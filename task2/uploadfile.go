package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	_ "os"

	"github.com/gin-gonic/gin"
)

// const pinataToken = "your-pinata-jwt-token"
const pinataUploadURL = "https://uploads.pinata.cloud/v3/files"
const pinataAPIBaseURL = "https://api.pinata.cloud/v3/files/private/download_link"

type GenerateDownloadLinkRequest struct {
	URL     string `json:"url" binding:"required"`     // 文件的Pinata URL
	Expires int64  `json:"expires" binding:"required"` // 链接过期时间（秒）
	Date    int64  `json:"date"`                       // 可选的日期时间戳
	Method  string `json:"method" binding:"required"`  // 请求方法，通常为"GET"
}

func main() {
	r := gin.Default()

	// 定义文件上传接口
	r.POST("/upload-to-pinata", uploadToPinata)
	r.POST("get-img-url", getImgUrl)

	// 启动服务
	fmt.Println("服务器启动在 http://localhost:8080")
	r.Run(":8080")
}

func uploadToPinata(c *gin.Context) {
	// 从请求中获取表单数据
	network := c.PostForm("network")
	name := c.PostForm("name")
	groupId := c.PostForm("group_id")
	keyvalues := c.PostForm("keyvalues")
	authorization := c.Request.Header.Get("Authorization")

	if keyvalues == "" {
		keyvalues = "{}" // 默认空对象
	}

	// 获取上传的文件
	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "获取文件失败: " + err.Error(),
		})
		return
	}

	// 打开文件
	src, err := file.Open()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "打开文件失败: " + err.Error(),
		})
		return
	}
	defer src.Close()

	// 创建multipart表单
	var requestBody bytes.Buffer
	writer := multipart.NewWriter(&requestBody)

	// 添加文本字段
	if err := writer.WriteField("network", network); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "添加network字段失败: " + err.Error(),
		})
		return
	}

	if err := writer.WriteField("name", name); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "添加name字段失败: " + err.Error(),
		})
		return
	}

	if groupId != "" {
		if err := writer.WriteField("group_id", groupId); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "添加group_id字段失败: " + err.Error(),
			})
			return
		}
	}

	if err := writer.WriteField("keyvalues", keyvalues); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "添加keyvalues字段失败: " + err.Error(),
		})
		return
	}

	// 添加文件字段
	dst, err := writer.CreateFormFile("file", file.Filename)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "创建文件字段失败: " + err.Error(),
		})
		return
	}

	// 将文件内容复制到表单
	if _, err := io.Copy(dst, src); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "复制文件内容失败: " + err.Error(),
		})
		return
	}

	// 完成表单构建
	if err := writer.Close(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "关闭表单写入器失败: " + err.Error(),
		})
		return
	}

	// 创建请求
	req, err := http.NewRequest("POST", pinataUploadURL, &requestBody)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "创建请求失败: " + err.Error(),
		})
		return
	}

	// 设置请求头
	req.Header.Set("Authorization", authorization)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	// 发送请求到Pinata
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "发送请求到Pinata失败: " + err.Error(),
		})
		return
	}
	defer resp.Body.Close()

	// 读取响应
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "读取响应失败: " + err.Error(),
		})
		return
	}

	// 返回Pinata的响应
	c.Data(resp.StatusCode, "application/json", respBody)
}

func getImgUrl(c *gin.Context) {
	// 1. 获取请求头中的Authorization
	authHeader := c.Request.Header.Get("Authorization")
	if authHeader == "" {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "缺少Authorization请求头",
		})
		return
	}

	// 2. 解析请求体
	var reqBody GenerateDownloadLinkRequest
	if err := c.ShouldBindJSON(&reqBody); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "请求参数无效: " + err.Error(),
		})
		return
	}

	// 3. 构建发送到Pinata的请求体
	pinataReqBody, err := json.Marshal(reqBody)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "序列化请求体失败: " + err.Error(),
		})
		return
	}

	// 4. 创建HTTP请求
	req, err := http.NewRequest(
		"POST",
		pinataAPIBaseURL,
		bytes.NewBuffer(pinataReqBody),
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "创建请求失败: " + err.Error(),
		})
		return
	}

	// 5. 设置请求头
	req.Header.Set("Authorization", authHeader)
	req.Header.Set("Content-Type", "application/json")

	// 6. 发送请求到Pinata
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "发送请求到Pinata失败: " + err.Error(),
		})
		return
	}
	defer resp.Body.Close()

	// 7. 读取Pinata的响应
	var responseMap map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&responseMap); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "解析Pinata响应失败: " + err.Error(),
		})
		return
	}

	// 8. 返回响应结果
	c.JSON(resp.StatusCode, responseMap)
}
