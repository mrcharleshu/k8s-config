**ELK部署手册**

[TOC]

## 一、概述
对于日志来说，最常见的需求就是收集、存储、查询展示，而开源社区刚好有对应的开源项目：

- filebeat + **logstash** (日志的收集和加工)
- **elasticsearch**（日志的存储和查询）
- **kibana**（日志的展示）

因为这些项目都是elastic.co的，所以我们将这几个组合起来就是ELK Stack

### logstash和filebeat
- 因为logstash是jvm跑的，资源消耗比较大，所以后来作者又用golang写了一个功能较少但是资源消耗也小的轻量级的logstash-forwarder。不过作者只是一个人，加入http://elastic.co公司以后，因为es公司本身还收购了另一个开源项目packetbeat，而这个项目专门就是用golang的，有整个团队，所以es公司干脆把logstash-forwarder的开发工作也合并到同一个golang团队来搞，于是新的项目就叫filebeat了。
- logstash 和filebeat都具有日志收集功能，filebeat更轻量，占用资源更少，但logstash 具有filter功能，能过滤分析日志。一般结构都是filebeat采集日志，然后发送到消息队列，redis，kafaka。然后logstash去获取，利用filter功能过滤分析，然后存储到elasticsearch中

### ELK使用流程
- 应用产生日志
- filebeat读取宿主机日志
- logstash使用grok规则结构化日志
- elasticsearch存储数据
- kibana查询

## 二、安装环境说明

ELK安装在稳定版本的Kubernetes集群之上，本次部署中：

- Kubernetes版本为：`1.11.3`
- ELK版本号全为：`6.5.1`

## 三、部署方式
- 使用helm
- 自定义部署文件

## 四、使用helm部署
> **Helm is the best way to find, share, and use software built for Kubernetes.**

Helm之于Kubernetes好比yum之于RHEL，或者apt-get之于Ubuntu。Helm使用Chart帮助我们管理应用，Chart就好像RPM一样，里面描述了应用及其依赖关系。主要概念：

- Chart：Helm管理的应用部署包，一个结构相对固定的目录或者tgz压缩文件，Chart之间可相互依赖
- Release：Chart部署之后的事例，每一次helm install就会生成一个新的release

关于ELK的chart在中国大陆的使用，使用以下命令查询到可安装版本只有一个，并且是incubator不是stable的。

```
➜  Stack git:(master) ✗ helm search elk
NAME                   	CHART VERSION	APP VERSION	DESCRIPTION
incubator/elastic-stack	0.11.1       	6          	A Helm chart for ELK
```
上述查询返回结果的chart资源的链接为：
`https://kubernetes-charts-incubator.storage.googleapis.com/elastic-stack-0.11.1.tgz`。

**由此可见，ELK Stack在中国区用helm来安装的社区和资源并未成熟，为了安装和之后升级的便利性考虑，决定放弃这种helm安装的方式，但是可以利用国外chart的源文件，仿照编写部署yaml文件，自定义版本号进行安装。**

可参考的chart或自定义部署文件样例：

- [Microsoft elk-acs-kubernetes chart](https://github.com/Microsoft/elk-acs-kubernetes)
- [Azure helm-elasticstack chart](https://github.com/Azure/helm-elasticstack)
- [GitHub上个人整理的AzureKubernetesService-ELK部署文件](https://github.com/atverma/AzureKubernetesService-ELK)
	
## 五、自定义部署文件
**全部部署文件存放在[Gogs / Enterprise / Stack](https://git.ruff.io/Enterprise/Stack/src/master/ELK/deploy)中。**

### 几个Kubernetes的概念：
#### 1、DaemonSet
**DaemonSet**保证在每个Node上都运行一个容器副本，常用来部署一些集群的日志、监控或者其他系统管理应用，[详细文档链接](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)
#### 2、PV & PVC
**PersistentVolume**（PV）和**PersistentVolumeClaim**（PVC）是k8s提供的两种API资源，用于抽象存储细节。管理员关注于如何通过pv提供存储功能而无需
关注用户如何使用，同样的用户只需要挂载pvc到容器中而不需要关注存储卷采用何种技术实现。
pvc和pv的关系与pod和node关系类似，前者消耗后者的资源。pvc可以向pv申请指定大小的存储资源并设置访问模式,这就可以通过Provision -> Claim 的方式，来对存储资源进行控制。[详细文档链接](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
#### 3、StatefulSet
**StatefulSet**本质上是Deployment的一种变体，在v1.9版本中已成为GA版本，它为了解决有状态服务的问题（对应**Deployments**和**ReplicaSets**是为无状态服务而设计），它所管理的Pod拥有固定的Pod名称，启停顺序，在StatefulSet中，Pod名字称为网络标识(hostname)，还必须要用到共享存储。

在Deployment中，与之对应的服务是service，而在StatefulSet中与之对应的headless service，headless service，即无头服务，与service的区别就是它没有Cluster IP，解析它的名称时将返回该Headless Service对应的全部Pod的Endpoint列表。
除此之外，StatefulSet在Headless Service的基础上又为StatefulSet控制的每个Pod副本创建了一个DNS域名

- [StatefulSet详细文档链接](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Headless Service 官方](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)
- [Headless Service O'Relly](https://www.oreilly.com/library/view/kubernetes-for-developers/9781788834759/1d7b03e7-eb9b-477e-a1ab-bd11c18836ff.xhtml)
- [Headless Service 博客](https://www.linuxea.com/1969.html)

## 六、部署过程
在上文提到的deploy目录中执行`deploy.sh`文件

```
➜  deploy git:(master) ✗ ./deploy.sh
namespace "elk" configured
secret "mrcharleshu-tls" created
storageclass.storage.k8s.io "es-data" configured
configmap "es-configmap" created
deployment.apps "elasticsearch-master" created
deployment.apps "elasticsearch-client" created
statefulset.apps "elasticsearch-data" created
service "elasticsearch" created
service "elasticsearch-data" created
service "elasticsearch-discovery" created
configmap "kibana-configmap" created
deployment.apps "kibana" created
service "kibana" created
configmap "filebeat-configmap" created
daemonset.apps "filebeat" created
configmap "logstash-configmap" created
deployment.apps "logstash" created
service "logstash" created
ingress.extensions "elk.ingress" created
```
一般7分钟左右会创建成功

## 七、日常运维之Logstash须知
Logstash在我们的集群中最重要的配置文件就是**Logstash_ConfigMap.yaml**中的**logstash.conf**，配置文件中间部分的filter是Logstash过滤日志，结构化日志的核心配置。
定义多个匹配规则，满足各个应用的日志输入格式

### 注意事项
- **在新项目启动时，输入日志应尽量和以上兼容**

### 参考资料
- [Logstash Configuration](https://www.elastic.co/guide/en/logstash/6.x/config-setting-files.html)
- [Input Plugin](https://www.elastic.co/guide/en/logstash/current/input-plugins.html)
- [Grok Filter Plugin](https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html)
- [Grok Processor](https://www.elastic.co/guide/en/elasticsearch/reference/current/grok-processor.html)
- [Grok Offcial Patterns](https://github.com/elastic/logstash/blob/v1.4.2/patterns/grok-patterns)
- [Output Plugin](https://www.elastic.co/guide/en/logstash/current/output-plugins.html)


## 八、日常运维之ElasticSearch须知
- 查看集群简况状况  
https://elasticsearch.mrcharleshu.com/_cluster/health?pretty
- 查看所有索引  
https://elasticsearch.mrcharleshu.com/_cat/indices?v
- 查看单个索引  
https://elasticsearch.mrcharleshu.com/k8slogidx_?pretty
- 查看master节点  
https://elasticsearch.mrcharleshu.com/_cat/master?v
- 查看节点信息  
https://elasticsearch.mrcharleshu.com/_cat/nodes?v
- 查看分片信息  
https://elasticsearch.mrcharleshu.com/_cat/shards?v

### 参考资料
- [Basic Concept](https://www.elastic.co/guide/en/elasticsearch/reference/current/_basic_concepts.html)
- [ElasticSearch Nodes](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html)
- [ElasticSearch Index](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-index.html)

## 九、日常运维之Kibana须知
- [Getting Started](https://www.elastic.co/guide/en/kibana/current/watcher-getting-started.html)
- [Watch UI](https://www.elastic.co/guide/en/kibana/current/watcher-ui.html)
- [Setting the Time Filter](https://www.elastic.co/guide/en/kibana/current/set-time-filter.html#set-time-filter)
