# iOSArchiveScript

iOS 自动打包脚本 并且自动拉取git提交记录 并通知到企业微信群

## 步骤：
### 1.将下载下来的4个文件放到你项目的根目录 如下图：
<img src="https://i.postimg.cc/m2Xg9tQV/17964cc4-b185-4ed8-9254-1a20d1d4bad0.png" width="633" >

### 2.配置参数
- 1.3个plist文件分别配置 你项目的`Bundle id` 和 `证书的profile`
<img src="https://i.postimg.cc/zBZcPF17/878dbd6d-39d7-4808-8ee3-da7e6110e33a.png" >

- 2.配置shell.sh参数：
<img src="https://i.postimg.cc/dQW9hjSf/03c32423-8267-493e-95e1-cc95ca7dff47.png" >

### 3.安装fir-cli
```
// 安装 fir-cli
sudo gem install fir-cli

// fir 登录 输入fir官网tolen
fir login

// fir-cli工具更新
fir upgrade
```

### 4.配置Xcode 自动更新build号脚本
```
buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${PROJECT_DIR}/${INFOPLIST_FILE}")

if [ "$buildNumber" == "\$(CURRENT_PROJECT_VERSION)" ]

then

buildNumber=$CURRENT_PROJECT_VERSION

fi

buildNumber=$(($buildNumber + 1))

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${PROJECT_DIR}/${INFOPLIST_FILE}"

echo "build number increase"
```
<img src="https://i.postimg.cc/QtjYgxDx/0a5815bf-af57-453f-8429-f51071f6c30f.png" >

### 5.运行shell.sh自动打包脚本
- 1.打开终端
- 2.cd 到你项目根目录(也就是你存放脚本的目录)
- 3.sh shell.sh

### 6.打包完成效果如下：
<img src="https://i.postimg.cc/cJvJkNNR/3955c30f-9923-4182-9a07-46dea7bc7e87.png" width="633" >
