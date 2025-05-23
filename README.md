# ubuntu 24.04 优化

## 安装vm-tools

```shell
#更新源
sudo apt update

# 基础工具（无界面版）
sudo apt install open-vm-tools -y
# OR
# 包含图形界面支持的完整版 (推荐)
sudo apt install open-vm-tools-desktop -y

# 重启以生效
sudo reboot

# 检查状态
sudo systemctl status vmtoolsd
```

## 安装换源工具（可选）

```shell
# 最新ubuntu 24.04 默认已经是国内源了，可以跳过此步骤

# 安装curl
sudo apt install curl -y

# 非root用户默认安装至 ~/.local/bin
curl https://chsrc.run/posix | bash

# root用户默认安装至 /usr/local/bin  (推荐)
curl https://chsrc.run/posix | sudo bash

# 自动换源
sudo chsrc set ubuntu


```

## 文件夹切换英文（可选）

```shell
# 适用于安装ubuntu 时选择了中文，文件夹默认为中文

# 语言改为英文
export LANG=en_US 

# 更新用户目录名称，执行此命令后按照提示框，选择新的目录名称即可
sudo xdg-user-dirs-gtk-update

# 切换回中文
export LANG=zh_CN
```

## 开启远程SSH以及ROOT登录

```shell
#!/bin/bash

# 1. 安装SSH服务（幂等操作）
if ! dpkg -l | grep -q openssh-server; then
  echo "正在安装OpenSSH服务..."
  sudo apt update && sudo apt install -y openssh-server  [[2]][[6]][[10]]
else
  echo "SSH服务已存在，跳过安装。"
fi

# 2. 配置允许Root登录（精确匹配）
if ! grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
  echo "配置SSH允许Root登录..."
  sudo sed -i '/^#PermitRootLogin prohibit-password$/s/^#//; /^PermitRootLogin/s/prohibit-password/yes/' /etc/ssh/sshd_config  [[7]][[8]]
else
  echo "Root登录已允许，跳过配置。"
fi

# 3. 重启SSH服务（仅在配置变更时重启）
if ! systemctl is-active --quiet ssh; then
  sudo systemctl restart ssh
  echo "SSH服务已重启。"
fi

echo "操作完成。可通过 ssh root@your_ip 登录"
```

## 使用国内源安装Docker-CE

```shell
# 使用阿里云源安装Docker-CE（不推荐，疑似失效）

# 添加阿里源秘钥
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -

# 写入Docker仓库地址
sudo sh -c 'echo "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list'

# or

# 使用清华源安装Docker-CE（推荐）

# 添加清华源秘钥
curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 写入Docker仓库地址
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 更新源并安装 Docker
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
sudo apt  install docker-compose  -y

# 验证是否成功安装了docker
sudo systemctl status docker    # 若进入分页了按Q退出
docker --version
```

### 若安装的Docker源有问题

```shell
# 如果添加的docker源有问题，可以用此方法删除


# 查看是否有此文件
ls /etc/apt/sources.list.d/ | grep docker


# 打开此文件，将其中的地址注释掉，例：http://mirrors.aliyun.com/docker-ce/linux/ubuntuhttp://mirrors.aliyun.com/docker-ce/linux/ubuntu
sudo vim /etc/apt/sources.list.d/docker.list

# 更新软件源即可
sudo apt update
```

## 使用SDKMAN管理软件包

[点击访问SDKMAN官方文档](https://sdkman.io/usage)

### SDKMAN安装

```shell
# 安装 SAKMAN 
curl -s "https://get.sdkman.io" | bash

# 安装后需要打开一个新终端才能生效
# 若想在在当前终端生效，执行此命令
source "$HOME/.sdkman/bin/sdkman-init.sh"

# 帮助信息
sudo sdk help


# 列出可用SDK列表
sdk list
```

### SDKMAN安装Java

```shell
# 如果你只是在单纯按照教程来做，可以直接使用此命令安装JDK8
sdk install java 8.0.442-tem

# JDK17
sdk install java 17.0.14-tem

# 设置为默认版本
sdk default java 8.0.442-tem
```

### SDKMAN 安装 Maven

```shell
# 查询 maven 可安装列表（按q退出）
sdk list maven

# 安装 maven 3.9.9
sdk install maven 3.9.9

# 查看 maven 版本以及目录
mvn -v
```

#### Maven 换源

```shell
# 安装后建议使用 chsrc 找出可用源手动换源
chsrc set maven

# 注：需要手动换源！！！
<mirror>
  <id>huawei</id>
  <mirrorOf>*</mirrorOf>
  <name>华为开源镜像站</name>
  <url>https://mirrors.huaweicloud.com/repository/maven/</url>
</mirror>
```

## Docker 安装 jenkins

> 支持jdk8的最新版jenkins-LTS版本：jenkins-2.346.1

### 拉取jenkins镜像

```shell
# 拉取镜像
docker pull jenkins/jenkins:latest-jdk8

# 创建jenkins数据目录
sudo mkdir -p /data/jenkins_home

# 注意 ：jenkins 容器默认以用户 ID 1000 运行，因此需要确保该目录对该用户可读写。（重要！！！
sudo chown -R 1000:1000 /data/jenkins_home
```

#### docker-compose-配置

> 命名为docker-compose.yml

```yml
services:
  jenkins:
    image: jenkins/jenkins:lts-jdk8
    container_name: jenkins
    ports:
      - "8080:8080"   # 映射 jenkins Web 界面端口
      - "50000:50000" # 映射 jenkins Agent 端口
    volumes:
      - /data/jenkins_home:/var/jenkins_home # 将宿主机目录挂载到容器内
```

#### 启动jenkins容器

```shell
# 在 docker-compose.yml 同级目录下运行（不推荐，见问题1）
# sudo docker-compose up -d

# 在 docker-compose.yml 使用 compose v2 运行（推荐）
sudo docker compose up -d

```

##### 问题1：ModuleNotFoundError: No module named 'distutils'

```shell
<< EOF
使用 docker-compose 运行时 提示缺少 distutils 软件包
使用命令 sudo apt-get install python3-distutils 也无法解决
提示ModuleNotFoundError
查阅资料得知这个打包的软件包在 3.12 中已被弃用
而 docker-compose 是基于 python 的compose v1 形式，自 2023 年 7 月 起，Compose V1 停止接收更新
推荐使用 docker compose 是 compose v2 的形式，其他命令 例 up 、down 风格保持一致
如 docker-compose up 等同于 docker compose up
[https://github.com/rashadphz/farfalle/issues/32]
EOF
# 当前版本 Docker version 28.0.2, build 0442a73 已集成，使用 compose v2 形式即可运行
# sudo apt install docker-compose-v2

```

### 配置jenkins国内源

> 清华源404了，这里选择华为源
> 地址：https://mirrors.huaweicloud.com/jenkins/updates/update-center.json
>
> 直接修改jenkins的工作目录中的hudson.model.UpdateCenter.xml文件
> 例我的：/data/jenkins_home/hudson.model.UpdateCenter.xml
>
> ```shell
> # 编辑配置文件
> vim /data/jenkins_home/hudson.model.UpdateCenter.xml
> ```

#### 修改配置文件

```xml
<?xml version='1.1' encoding='UTF-8'?>
<sites>
  <site>
    <id>default</id>
    # 修改为华为源
    <url>https://mirrors.huaweicloud.com/jenkins/updates/update-center.json</url>
  </site>
</sites>
```

#### 重启 jenkins 容器

```shell
# 重启容器
systemctl restart jenkins
```

### 登录jenkins

> 换源结束后，按照【ip:8080】访问 jenkins web 页面，例：http://192.168.0.31:8080/

```shell
<<EOF
密码位置位于/var/jenkins_home/secrets/initialAdminPassword
我们将jenkins_home映射到了/data/jenkins_home
EOF
# 获取解锁密码
vim /data/jenkins_home/secrets/initialAdminPassword
```

#### 问题2：由于版本过低无法安装插件

```shell
<<EOF
还好我们使用的是 docker 方式安装，升级起来比较容易
EOF
# 第一步，回到 docker-compose.yml 所在路径
# 此命令会删除之前创建的 docker 容器
sudo docker compose down


<<EOF
接下来编辑 docker-compose.yml 文件
将 image: jenkins/jenkins:lts-jdk8 改为 image: jenkins/jenkins:lts
然后重新创建容器
EOF
# 编辑文件
vim docker-compose.yml

# 编辑完成后启动
sudo docker compose up -d

<<EOF
如果忘记密码，可以看下这个文件 jenkins_home/secrets/initialAdminPassword
EOF
```

### 将jdk8映射到容器

> 因为改用了 jenkins 最新版，默认 jdk 是17，这里我的项目需要用 jdk8 打包，所以需要将宿主机的 jdk 8 映射到容器中

#### 修改 docker-compose.yml 文件

```yml
services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins
    ports:
      - "8080:8080"   # 映射 Jenkins Web 界面端口
      - "50000:50000" # 映射 Jenkins Agent 端口
    volumes:
      - /data/jenkins_home:/var/jenkins_home # 将宿主机目录挂载到容器内
      # 左边的是宿主机的 jdk 目录，我们上述使用sdkman 默认是安装到此目录，如果你安装到了其他目录需要修改（可以使用whereis java 查看
      # 注：此目录是 root 目录，需要确保你拥有 root 权限
      - /root/.sdkman/candidates/java/8.0.442-tem:/java/8.0.442-tem # 映射 JDK
```

#### 重新启动 docker compose

```shell
# 切换到 docker-compose.yml 所在目录,删除容器
sudo docker compose down

# 重新创建
sudo docker compose up
```

### 将 Maven 映射到容器

```shell
# 如果是按照上述教程安装的 maven 则默认安装目录在 /root/.sdkman/candidates/maven/3.9.9

```

#### 修改 docker-compose.yml文件

##### 问题3：安装 Maven 后添加环境变量后重新运行失败

> 原因：因为只给 maven 添加了环境变量，容器依赖于自带的 jdk 环境变量，无法运行，所以

```yml
services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins
    ports:
      - "8080:8080"   # 映射 Jenkins Web 界面端口
      - "50000:50000" # 映射 Jenkins Agent 端口
    volumes:
      - /data/jenkins_home:/var/jenkins_home # 持久化 Jenkins 数据
      - /root/.sdkman/candidates/java/8.0.442-tem:/data/java/8.0.442-tem # 映射宿主机的 JDK 8 路径
      - /root/.sdkman/candidates/maven/3.9.9:/data/maven/3.9.9 # 映射宿主机的 Maven 路径
    environment:
      - MAVEN_HOME=/data/maven/3.9.9 # 设置 Maven 的环境变量
      - PATH=/opt/java/openjdk/bin:/data/maven/3.9.9/bin:${PATH} # 将容器自带的 JDK 17 和 Maven 的 bin 目录添加到 PATH
```

## Jenkins 配置 前端项目

> 发现了官方源可以直连
>
> 官方的镜像地址池：[Mirrorstats](https://get.jenkins.io/index.html?mirrorstats)
>
> 其他可用 jenkins 镜像源：[http://ftp.belnet.be](http://ftp.belnet.be/)
>
> 参考：[jenkins 安装插件依赖的坑 - 昆虫白 - 博客园](https://www.cnblogs.com/byhh/p/17641238.html)

### 配置 gitlab

1. 配置一个 gitlab api 令牌

2.

3.

### 安装NVM

```shell
# 脚本一键安装
sudo curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash

# 配置变量
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# 刷新 配置
source ~/.bashrc

# 查看 nvm 版本
nvm -v

# 安装指定版本 nodejs
nvm install 14.21.3

# 查看 nodejs 版本
node -v

# 设置默认 nodejs 版本
nvm use 14.21.3
```


