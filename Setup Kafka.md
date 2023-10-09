##Kafka
####1. Giới thiệu về kafka
Là hệ thống message pub/sub phân tán (distributed messaging system). Bên pulbic dữ liệu được gọi là producer, bên subscribe nhận dữ liệu theo topic được gọi là consumer. Kafka có khả năng truyền một lượng lớn message theo thời gian thực, trong trường hợp bên nhận chưa nhận message vẫn được lưu trữ sao lưu trên một hàng đợi và cả trên ổ đĩa bảo đảm an toàn. Đồng thời nó cũng được replicate trong cluster giúp phòng tránh mất dữ liệu.

![mô hình kafka](/img/kafka-simple.png)

Các khái niệm trong kafka:
- **Producer**: đẩy message vào topic, dữ liệu được gửi đến partition của topic lưu trữ trên ``broker``
- **Consumer**: Dùng để subscribe vào topic, các ``consumer`` được định danh bằng các group name. Nhiều ``consumer`` có thể cùng đọc 1 topic
- **topic**: Dữ liệu truyền trong kafka theo `topic`, khi cần truyền dữ liệu cho các ứng dụng khác nhau thì sẽ tạo ra các `topic` khác nhau
- **partition**: Là nơi lưu trữ dữ liệu cho một `topic`. Một `topic` nó thể được phân bố lưu trữ trên một hoặc nhiều `parrtition`. Trên mỗi `partition` dữ liệu lưu trữ cố định và được gán cho một ID gọi là `offset`.
- **broker**: Là một server, nơi quản lý các `partition`
- **zookeper**: được dùng để quản lý và bố trí các `broker`

![mô hình chi tiết kafak](/img/kafka-structure.png)

####2. Cài đặt kafka trên máy local
#####2.1 Chuẩn bị máy chủ kafka
- Chúng ta sẽ sử dụng winsubsystem (WSL) trên windows 11 để làm máy chủ kafka
- Bật tính năng Winsubsystem trên windows:
> B1: Vào Control Panel > Programs > Chọn Turn Windows features on or off (Programs and Features)
> B2: Tick vào Virtual Machine Platform, Windows Hypervisor Platform, Windows Subsystem for Linux
> B3: OK

![Enable WSL](/img/Screenshot%202023-10-06%20103951.png)

- Cài đặt HĐH Ubuntu cho Windows Subsystem (WSL)
> Vào Microsoft Store > Search Ubuntu > Install Ubuntu bản LTS

![Install Ubuntu](/img/Screenshot%202023-10-06%20104245.png)

- Khởi động WSL Ubuntu
> B1: search Ubuntu trên windows 11
> B2: config username và password cho HĐH Ubuntu (note lại 2 cái này để không quên)

- Config IP cho Ubuntu
> B1: Tắt Ubuntu đang chạy
> B2: run file `changeIPAddress.ps1`
> B3: Vào lại Ubuntu
> B4: Kiểm tra xem ip đã được thay đổi hay chưa bằng lệnh `ip addr`

![change ip](/img/Screenshot%202023-10-06%20112952.png)

- Bật kết nối ssh cho máy chủ ubuntu
```shell
sonmv@SONMV:~$ sudo service ssh start
```
Bây giờ mình có thể mở máy chủ ubuntu bằng WinSCP Tool hoặc MobaXterm Tool với địa chỉ IP là 192.168.0.2 port 22

- Kết nối với máy chủ ubuntu sử dụng WinSCP
![winscp](/img/Screenshot%202023-10-06%20114720.png)

> username: tên đăng nhập vào ubuntu ta config lúc đầu cài đặt ubuntu
> password: password ta config lúc đầu cài đặt ubuntu

- Cài đặt java cho máy chủ
Sau khi vào máy chủ ubuntu thông qua WinSCP, copy `\tool\jdk-11.0.11` vào thư mục `/home/username/` (`username` là tên user đăng nhập).
![copy jdk](/img/Screenshot%202023-10-06%20135443.png)

Tại cửa sổ commanf line  của ubuntu thực hiện các bước sau:
> B1: Show danh sách các thư mục hiện có trong thư mục `/home/username`
```shell
sonmv@SONMV:~$ ll -a
```
![show folder](/img/Screenshot%202023-10-06%20135943.png)

Để ý vào file .profile, file này sẽ tạo biến mối trường cho java (giống với path enviroment trong window)
```shell
sonmv@SONMV:~$ nano .profile
```
![set path](/img/Screenshot%202023-10-06%20140430.png)

Thêm 2 dòng như trong ảnh vào cuối file, sau đó ấn Ctrl + X, ấn Y (đồng ý save), ấn Enter để hoàn thành

Sau đó chạy câu lệnh
```shell
sonmv@SONMV:~$ . .profile
```

Kiểm tra xem đã config java thành công hay chưa
```shell
sonmv@SONMV:~$ echo $JAVA_HOME
```
Kết quả trả về là `/home/sonmv/jdk-11.0.11` là thành công

#####2.2 Cài đặt kafka confluent trên máy chủ ubuntu
- Download confluent kafka community từ trang chủ của kafka (link: `https://packages.confluent.io/archive/6.2/`) về máy tính
![kafka archive](/img/Screenshot%202023-10-09%20211502.png)
- Giải nén file confluent-6.2.0.zip
- Sử dụng WinSCP để copy `confluent-6.2.0` vào `/home/username`
![kafka-copy](/img/Screenshot%202023-10-09%20212745.png)

#####2.3 Config các thành phần của kafka
1. Config server (hay còn gọi là broker): 
    - File cấu hình của broker nằm trong thư mục `/home/sonmv/confluent-6.2.0/etc/kafka/server.properties`
    - Ta cần cấu hình số lượng partition, offset và replica cho phù hợp với nhu cầu sử dụng kafka (ở đây hướng dẫn cấu hình với 1 broker, ngoài ra ta có thể cấu hình nhiều broker chạy song song để tăng hiệu năng của hệ thống queue message)
    - cấu hình chi tiết như sau:
        ****Server Basics****
        ```properties
        broker.id=0
        ```
        ****Socket Server Settings****
        ```properties
        listeners=PLAINTEXT://:9092

        #Hostname and port the broker will advertise to producers and consumers. If not set, 
        #it uses the value for "listeners" if configured.  Otherwise, it will use the value
        #returned from java.net.InetAddress.getCanonicalHostName().
        advertised.listeners=PLAINTEXT://192.168.0.2:9092

        #Maps listener names to security protocols, the default is for them to be the same. See the config documentation for more details
        #listener.security.protocol.map=PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL

        #The number of threads that the server uses for receiving requests from the network and sending responses to the network
        num.network.threads=3

        #The number of threads that the server uses for processing requests, which may include disk I/O
        num.io.threads=8

        #The send buffer (SO_SNDBUF) used by the socket server
        socket.send.buffer.bytes=102400

        #The receive buffer (SO_RCVBUF) used by the socket server
        socket.receive.buffer.bytes=102400

        #The maximum size of a request that the socket server will accept (protection against OOM)
        socket.request.max.bytes=104857600
        ```
        ***advertised.listeners***: lắng nghe message đẩy lên qua boostrap-server có ip là 192.168.0.2 cổng 9092, cái ip 192.169.0.2 là ip máy chủ ubuntu ta đã config từ đầu ở trên
        
        ****Log Basics****
        ```properties
            #A comma separated list of directories under which to store log files
            log.dirs=/home/sonmv/confluent-6.2.0/data/kafka-logs/0

            #The default number of log partitions per topic. More partitions allow greater
            #parallelism for consumption, but this will also result in more files across
            #the brokers.
            num.partitions=1

            #The number of threads per data directory to be used for log recovery at startup and flushing at shutdown.
            #This value is recommended to be increased for installations with data dirs located in RAID array.
            num.recovery.threads.per.data.dir=1
        ```
        ***log.dirs*** : đường dẫn thư mục sẽ chứa log kafka khi chạy, sử dụng để check lỗi khi trong quá trình làm việc với kafka bị lỗi
        ***num.partitions***: số lượng partition cho một server (hay broker), số lượng partition để bằng với số lượng ta muốn tạo broker, ở đây ta config cho 1 broker nên số lượng partition là 1
        
        ****Internal Topic Settings****
        ```properties
        #The replication factor for the group metadata internal topics "__consumer_offsets" and "__transaction_state"
        #For anything other than development testing, a value greater than 1 is recommended to ensure availability such as 3.
        offsets.topic.replication.factor=2
        transaction.state.log.replication.factor=2
        transaction.state.log.min.isr=2
        ```
        Các giá trị khác giữ mặc định

2. Config connect-distributed.properties 
    - File này nắm trong thư mục nằm trong thư mục `/home/sonmv/confluent-6.2.0/etc/kafka/`
    - Đây là file cấu hình để sử dụng được các plugin ngoài vào kafka và sử dụng các kafka connector (ví dụ: khi đẩy data lên topic xong từ topic đẩy vào database thì việc đẩy nội dung message từ topic vào DB là do connector đảm nhiệm)
    - Cấu hình:
        ```properties
        bootstrap.servers=192.168.0.2:9092
        key.converter.schemas.enable=false
        value.converter.schemas.enable=false
        offset.storage.topic=connect-offsets
        offset.storage.replication.factor=2
        offset.storage.partitions=3
        config.storage.topic=connect-configs
        config.storage.replication.factor=2
        status.storage.topic=connect-status
        status.storage.replication.factor=2
        #status.storage.partitions=3
        rest.port=8083
        plugin.path=/home/sonmv/confluent-6.2.0/share/java
        ```
        ***bootstrap.servers***: chỉ ra server để connect-distribute chạy, 192.168.0.2 là ip máy chủ ubuntu ta đã config ở trên
        ***plugin.path***: đường dẫn đến các thư viện plugin ta muốn thêm vào cho kafka chạy và sửu dụng nó trong kafka (ví dụ: cái để đẩy message vào DB là 1 plugin connector, ta có thể tìm trên mạng được 1 file .jar, copy file này vào đường dẫn được config ở 'plugin.path' và khởi động lại kafka, lúc đó kafka sẽ nhận được plugin này và ta sử dụng nó cho mục đích của mình).

3. Config zookeeper.properties
    - File này nắm trong thư mục nằm trong thư mục `/home/sonmv/confluent-6.2.0/etc/kafka/`
    - Cấu hình
    ```properties
        dataDir=/home/sonmv/confluent-6.2.0/data/zookeeper
    ```
    ***dataDir***: đường dẫn ghi log khi chạy zookeeper
4. Config schema-registry.properties
    - File này nắm trong thư mục nằm trong thư mục `/home/sonmv/confluent-6.2.0/etc/schema-registry/`
    - File này có tác dụng transform dữ liệu trước khi vào topic hoặc sau khi lấy ra từ topic. Đại khái là nó chuyển đổi dữ liệu đẩy lên topic theo 1 form mà mình mong muốn.
    - Cấu hình
    ```properties
        kafkastore.bootstrap.servers=PLAINTEXT://192.168.0.2:9092
    ```

#####2.4: Khởi chạy kafka
- Ta đã cấu hình xong kafka, bây giờ là phần chạy
- Kafka được chạy theo thứ tự như sau: 
    - chạy zookeeper đầu tiên > chạy server (broker) > chạy schema-registry
- Run kafka:
    - Connect vào máy chủ ubuntu thông qua WinSCP.
    - Tạo file run.sh trong thư mục `/home/sonmv/confluent-6.2.0`
    - Chuột phải vào file run.sh chọn Edit paster đoạn mã sau vào và save lại
    ```shell
        export KAFKA_HOME=/home/sonmv/confluent-6.2.0
        $KAFKA_HOME/bin/schema-registry-stop
        $KAFKA_HOME/bin/kafka-server-stop $KAFKA_HOME/etc/kafka/server1.properties
        $KAFKA_HOME/bin/kafka-server-stop $KAFKA_HOME/etc/kafka/server2.properties
        $KAFKA_HOME/bin/kafka-server-stop $KAFKA_HOME/etc/kafka/server3.properties
        $KAFKA_HOME/bin/zookeeper-server-stop
        sleep 20
        rm -Rf $KAFKA_HOME/logs/*
        rm -Rf $KAFKA_HOME/data/kafka-logs/*
        rm -Rf $KAFKA_HOME/data/zookeeper/*
        echo 'Starting Zookeeper'
        $KAFKA_HOME/bin/zookeeper-server-start -daemon $KAFKA_HOME/etc/kafka/zookeeper.properties
        sleep 10
        echo 'Starting brockers'
        $KAFKA_HOME/bin/kafka-server-start -daemon $KAFKA_HOME/etc/kafka/server1.properties
        $KAFKA_HOME/bin/kafka-server-start -daemon $KAFKA_HOME/etc/kafka/server2.properties
        $KAFKA_HOME/bin/kafka-server-start -daemon $KAFKA_HOME/etc/kafka/server3.properties
        sleep 20
        $KAFKA_HOME/bin/zookeeper-shell localhost:2181 ls /brokers/ids
        $KAFKA_HOME/bin/schema-registry-start -daemon $KAFKA_HOME/etc/schema-registry/schema-registry.properties
    ```
- Stop kafka:
    - Làm tượng tự tạo file stop.run sau đó paste đoạn mã sau vào và save lại
    ```shell
        export KAFKA_HOME=/home/sonmv/confluent-6.2.0
        $KAFKA_HOME/bin/schema-registry-stop $KAFKA_HOME/etc/schema-registry/schema-registry.properties
        $KAFKA_HOME/bin/kafka-server-stop $KAFKA_HOME/etc/kafka/server1.properties
        $KAFKA_HOME/bin/kafka-server-stop $KAFKA_HOME/etc/kafka/server2.properties
        $KAFKA_HOME/bin/kafka-server-stop $KAFKA_HOME/etc/kafka/server3.properties
        $KAFKA_HOME/bin/zookeeper-server-stop $KAFKA_HOME/etc/kafka/zookeeper.properties
        sleep 20
        rm -Rf $KAFKA_HOME/logs/*
        rm -Rf $KAFKA_HOME/data/kafka-logs/*
        rm -Rf $KAFKA_HOME/data/zookeeper/*
    ```