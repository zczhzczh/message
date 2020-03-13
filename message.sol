pragma solidity ^0.4.17; //编译器版本为0.4.24

contract simplemessage {//创建名为“信息”的合约

    uint internal password = 998; //验证码
    uint firstnow;//系统零点（第一次读表操作的时刻）
    uint internal carryouttransaction; //执行交易（用于判断交易是否进行过）
    uint internal transactiontime; //交易周期（每次交易完成后++）（用于给用户展示）
    uint internal transactiontimecopy;
    uint internal initializenowfeaturenumber;//初始化系统零点特征数字
    uint internal initializetransactionfeaturenumber;//初始化交易特征数字
    uint internal idnumber;//用户序号，按注册顺序不断累积
    uint internal transactionnumber;//每笔交易的序号
    uint internal equilibratenumber;//每笔余量平衡的序号
    address internal administratorsaddress;//管理员地址
    address internal systemaccountsaddress;//平衡账户地址

    struct deal {//“合同”结构体。
        uint dealsid;//合同编号（合约自动生成：用户id*100+合同序号）
        uint target1id; //合同中生产者编号
        uint target2id; //合同中消费者编号
        int dealsplan; //合同约定的交易量
        int dealsprice; //合同约定的交易单价
    }
    struct user {//”用户”结构体。
        string name; //名称
        uint id; //ID
        int plan; //申报量
        int plancopy;//申报量副本
        int pastplan;//上一周期撮合成功申报量
        int pastpastplan;//上一周期交易计划
        int price; //报价
        address useraddress;
        int balance; //钱包余额
        int powertype; //类型
        uint[] transactionidsgroup;//交易编号数组
        uint[] equilibrateidsgroup;//余量平衡编号数组
    }
    struct right{//“权限”结构体
        int initializeuserfeaturenumber;//初始化用户信息特征数字
        int declareright;//申报权限
        int inquireright;//撮合权限
        int equilibrateright;//余量平衡权限
    }
    struct systemaccount {//“系统账户”结构体
        uint[] equilibrateidsgroup;//余量平衡编号数组
        int price;//公共电网电价
        int balance;//公共电网钱包
        int positiveplan;//购电量
        int negativeplan;//售电量
    }
    struct ammeter {//“电表”结构体
        int ammeterplan;//周期电量
        int totalelectricity;//电表电量
        uint ammetersid;//电表特征码
        uint readnumber;//读表次数
        int[] totalelectricitysgroup;//电表电量数组
        int[] electricitysgroup;//周期电量数组
    }
    struct transactionmessage{//“交易信息”结构体
        uint transactionmessagestime;//交易周期
        uint transactionid;//交易编号
        string producersname;//生产者名字
        uint producersid;//生产者id
        string customersname;//消费者名字
        uint customersid;//消费者id
        int transactionplan;//交易电量
        int transactionprice;//交易价格
    }
    struct equilibratemessage{//“余量平衡信息”结构体
        uint equilibratemessagetime;//余量平衡周期
        uint equilibrateid;//余量平衡编号
        string equilibratename;//余量平衡对象名字
        uint usersid;//对象id
        int equilibrateplan;//平衡电量
        int equilibrateprice;//平衡电价
    }
    systemaccount s;//系统账户s

    mapping(uint => user) public idtousers; //“用户编号指向用户”的映射
    mapping(uint => deal) public deals; //“合同编号指向合同”的映射
    mapping(address => user) public users; //“用户地址指向用户”的映射
    mapping(address => systemaccount) public systemaccounts;//“系统账户地址指向系统账户”的映射
    mapping(uint => transactionmessage) public transactionmessages;//“交易信息编号指向交易信息”的映射
    mapping(uint => equilibratemessage) public equilibratemessages;//余量平衡信息映射
    mapping(address => ammeter) public ammeters;//“电表地址指向电表”的映射
    mapping(uint => ammeter) public idtoammeters;//“电表标识符指向电表”的映射
    mapping(address => right) public rights;//“用户地址指向用户权限”的映射

    transactionmessage[] public transactionmessagesgroup;//"交易信息"数组
    uint[] public producersidgroup; //定义名为“生产者编号集合”的数组，成员类型为uint
    uint[] public customersidgroup; //定义名为“消费者编号集合”的数组，成员类型为uint

    event showtransactionmessage (uint a, uint b, string c, string d, int e, int f);//监听交易：当前周期，交易序号，生产者名称，消费者名称，交易量，交易单价
    event showequilibratemessage (uint a,uint b, string c, int d, int e);//监听余量平衡：当前周期，余量平衡序号，用户名称，平衡偏差电量，公共电网电价
    event showblockmessage (address a,uint b,uint c,uint d,uint e);//监听区块信息：矿工地址，难度系数，汽油限制，区块编号，时间戳

    constructor() payable public{//构造函数
        password = 998;//定义验证码
        administratorsaddress = msg.sender;//存储管理者地址
        systemaccountsaddress = msg.sender;//存储公共电网地址
    }

    function ReadAmmeter(int _ammeterplan,int _totalelectricity, uint _ammetersid) public returns(string) {//“读表”函数，输入数据为：实际电表电量，电表标识码
        initializenow();//调用“初始化时间”函数
        initializetransaction(); //调用“初始化交易”函数
        if(transactiontimecopy == 95) DeleteAmmeter();//清空电表
        transactiontimecopy = transactiontime;//复制交易周期
        ammeters[msg.sender].readnumber++;//读表次数++
        ammeters[msg.sender].ammetersid = _ammetersid;//记录电表id
        ammeters[msg.sender].electricitysgroup.push(_ammeterplan);//记录周期电量数组
        ammeters[msg.sender].totalelectricitysgroup.push(_totalelectricity);//记录总电量数组
        ammeters[msg.sender].ammeterplan = _ammeterplan;//将输入的电量存储在电表结构体中
        ammeters[msg.sender].totalelectricity = _totalelectricity;//记录电量
        rights[msg.sender].equilibrateright = 0;//余量平衡权限置0
        return ("读表成功");
    }
    function GetAmmeter() public view returns(uint,uint, uint, int, int, int[], int[]){//返回电表信息
        return(transactiontime,//当前周期
            ammeters[msg.sender].readnumber,//读表次数
            ammeters[msg.sender].ammetersid,//电表ID
            ammeters[msg.sender].ammeterplan,//周期电量
            ammeters[msg.sender].totalelectricity,//电表电量
            ammeters[msg.sender].electricitysgroup,//周期电量数组
            ammeters[msg.sender].totalelectricitysgroup);//电表电量数组
    }
    function DeleteAmmeter() public {//清空电表
        delete ammeters[msg.sender].electricitysgroup;//删除周期电量数组
        delete ammeters[msg.sender].totalelectricitysgroup;//删除总电量数组
        ammeters[msg.sender].ammeterplan = 0;//电量归零
        ammeters[msg.sender].totalelectricity = 0;//周期电量归零
        ammeters[msg.sender].readnumber = 0;//读表次数归零
    }
    function GetNowUsersMessage() public view returns(string, uint ,int , int, int, int, int, uint[], int, int, uint[]) {//“得到当前用户信息”函数
        return (users[msg.sender].name,//名字
                users[msg.sender].id,//id
                users[msg.sender].plancopy,//申报量副本
                users[msg.sender].plan,//未中标量
                users[msg.sender].pastpastplan,//上一周期交易计划
                ammeters[msg.sender].ammeterplan,//实际电表电量
                users[msg.sender].price,//报价
                users[msg.sender].transactionidsgroup,//交易编号数组
                users[msg.sender].balance,//钱包余额
                users[msg.sender].powertype,//能源类型
                users[msg.sender].equilibrateidsgroup);//余量平衡编号数组
    }
    function initializenow() internal {//定义名为“初始化交易周期”的函数
        if(initializenowfeaturenumber == 0){//如果系统零点未被设置过，则执行下面语句
            transactiontime = 0; //初始化“交易周期”序号为 0
            transactiontimecopy = 0;//交易周期副本归零
            carryouttransaction = 0;//初始化“执行交易”为0
            firstnow = now ;//定义系统零点为第一次读表的区块时间
            initializetransactionfeaturenumber = 0;//初始化“初始化交易特征数字”为1
            initializenowfeaturenumber = 1;//初始化“初始化时间特征数字”为1
        }
    }
    function arrangebypricefromlow() internal {//定义名为“按报价从低到高排序”函数。
        if(producersidgroup.length != 0){//如果数组成员不为零则进行排序
            uint t;//定义一个中间变量
            for(uint i = 0;i < (producersidgroup.length - 1);i++) {//n个数的数列总共扫描n-1次
                for(uint j = 0;j < producersidgroup.length-i-1;j++) {//每一趟扫描到a[n-i-2]与a[n-i-1]比较为止结束
                    if(idtousers[producersidgroup[j]].price > idtousers[producersidgroup[j+1]].price) {//后一位数比前一位数小的话，就交换两个数的位置（升序）
                        t = producersidgroup[j+1];
                        producersidgroup[j+1] = producersidgroup[j];
                        producersidgroup[j] = t;
                    }
                }
            }
        }
    }
    function arrangebypricefromhigh() internal {//定义名为“按报价从高到低排序”函数
        if(customersidgroup.length != 0){//如果数组成员不为零则进行排序
            uint t; //定义一个中间变量
            for(uint i = 0;i < (customersidgroup.length-1);i++) {//n个数的数列总共扫描n-1次
                for(uint j = 0;j < (customersidgroup.length-i-1);j++) {//每一趟扫描到a[n-i-2]与a[n-i-1]比较为止结束
                    if(idtousers[customersidgroup[j]].price < idtousers[customersidgroup[j+1]].price) {//后一位数比前一位数大的话，就交换两个数的位置（降序）
                        t = customersidgroup[j+1];
                        customersidgroup[j+1] = customersidgroup[j];
                        customersidgroup[j] = t;
                    }
                }
            }
        }
    }
    function initializeuser(address _address) internal {//“初始化用户”函数
        if (rights[_address].initializeuserfeaturenumber == 1) {//如果用户未被初始化过，则进行初始化
            users[_address].plan = 0;//申报量归零
            users[_address].plancopy = 0;//申报量副本归零
            users[_address].price = 0;//报价归零
            ammeters[_address].ammeterplan = 0;//电表电量归零
            rights[_address].initializeuserfeaturenumber = 0;//初始化特征数字归零
            rights[_address].inquireright = 0;//交易权限归零
            rights[_address].declareright = 0;//申报权限归零
        }
    }
    function initializetransaction() internal {//定义名为“初始化数组”的函数
        if(initializetransactionfeaturenumber == 0){//如果交易未被初始化过
            delete producersidgroup; //清空生产者编号数组
            delete customersidgroup; //清空消费者编号数组
            delete transactionmessagesgroup;//清空交易心思数组
            initializetransactionfeaturenumber = 1; //将“初始化数组ed”赋 1
            carryouttransaction = 0 ; //将”执行交易”赋0
        }
    }
    function transaction(uint i, uint j, int x, int y) internal {//定义名为“交易”的函数，输入数据为：生产者a,消费者b，交易总量x,交易单价y
        transactionnumber++;//交易编号+1
        idtousers[i].plan = idtousers[i].plan - x; //生产者a的申报量修改为：生产者a的申报量-交易总量x
        idtousers[i].balance = idtousers[i].balance + x*y; //生产者a的余额修改为：生产者a的余额+交易总量x*交易单价y
        idtousers[j].plan = idtousers[j].plan+x; //消费者b的申报量修改为：消费者b的申报量+交易总量x
        idtousers[j].balance = idtousers[j].balance - x*y; //消费者b的余额修改为：消费者b的余额-交易总量x*交易单价y
        transactionmessages[transactionnumber].transactionid = transactionnumber;//存储交易编号
        transactionmessages[transactionnumber].producersname = idtousers[i].name;//存储生产者名字
        transactionmessages[transactionnumber].producersid = idtousers[i].id;//存储生产者编号
        transactionmessages[transactionnumber].customersname = idtousers[j].name;//存储消费者名字
        transactionmessages[transactionnumber].customersid = idtousers[j].id;//存储消费者编号
        transactionmessages[transactionnumber].transactionplan = x;//存储成交电量
        transactionmessages[transactionnumber].transactionprice = y;//存储成交电价
        transactionmessages[transactionnumber].transactionmessagestime = transactiontime;//存储交易周期
        transactionmessagesgroup.push(transactionmessages[transactionnumber]);//存储交易编号数组
        emit showtransactionmessage(transactiontimecopy,transactionnumber,idtousers[i].name,idtousers[j].name,x,y);//监听交易信息
    }
    function initializeidnumber()public{//“初始化id”函数
        idnumber = 0;//id归零
    }
    function restart() public {//“初始化系统”函数
        initializenowfeaturenumber = 0;//初始化系统特征数字归零
    }
    function Verify(uint _password) public view returns (string){//定义名为“核验”的函数
        if(_password == password) return("验证码正确");//正确
        else return("验证码错误");//错误
    }
    //定义名为“注册”的函数
    function Register(string _name, int _powertype) public returns(string) {
            uint _id;
            idnumber = idnumber + 1;//ID累积
            _id = idnumber;
            users[msg.sender].name = _name; //存储申报量
            users[msg.sender].id = _id; //存储报价
            users[msg.sender].powertype = _powertype; //存储钱包余额
            users[msg.sender].balance = 100000000; //存储钱包余额
            users[msg.sender].useraddress = msg.sender; //存储钱包余额
            idtousers[users[msg.sender].id] = users[msg.sender];
            return ("注册成功");
    }
    function Declare(int _plan, int _price) public returns (string){//定义名为“申报”的函数,输入数据为：申报量，报价
        initializenow();
        initializetransaction(); //调用“初始化交易”函数
                rights[msg.sender].equilibrateright = 0;//余量平衡权限赋0
                rights[msg.sender].initializeuserfeaturenumber = 1;//初始化特征数字赋1
                users[msg.sender].plan = _plan;//存储申报量
                users[msg.sender].plancopy = _plan;//存储申报量副本
                users[msg.sender].price = _price;//存储报价
                int y;
                if (users[msg.sender].plan > 0){ //生产者
                        if(rights[msg.sender].declareright == 0){//如果未申报过
                        producersidgroup.push(users[msg.sender].id);//存入生产者数组
                        rights[msg.sender].declareright = 1;//申报权限赋1
                        }
                        idtousers[users[msg.sender].id] = users[msg.sender];//结构体存入ID映射
                        return ("申报成功，请点击下一步");
                }
                else if(users[msg.sender].plan < 0) {//消费者
                        if(y > users[msg.sender].balance) return("余额不足，请修改合同或修改余额");
                        else{
                            if(rights[msg.sender].declareright == 0){//如果未申报过
                            customersidgroup.push(users[msg.sender].id);//存入消费者数组
                            rights[msg.sender].declareright = 1;//申报权限赋1
                            }
                            idtousers[users[msg.sender].id] = users[msg.sender];//结构体存入ID映射
                            return ("申报成功，请点击下一步");
                        }
                }
                else return ("申报失败，申报量不能为0");
  }
    function Inquire() public returns(string) {//定义名为“查询”的函数
                address _address;
                uint m;
                if(carryouttransaction == 0){ //如果交易结果未被查询过
                    carryouttransaction = 1; //将“执行交易”赋1,表示交易被查询过
                    transactionbytype(); //调用“按类型交易”函数
                    for(uint i = 0;i < producersidgroup.length;i++){
                      _address = idtousers[producersidgroup[i]].useraddress;
                      m = idtousers[producersidgroup[i]].id;
                      users[_address].plan = idtousers[m].plan;//提取申报量
                      users[_address].balance = idtousers[m].balance;//提取余额
                      for(uint k = 0; k < transactionmessagesgroup.length; k++){//记录交易编号数组
                          if(m == transactionmessagesgroup[k].producersid || m == transactionmessagesgroup[k].customersid){
                              users[_address].transactionidsgroup.push(transactionmessagesgroup[k].transactionid);
                    }
                  }
                }
                    for(uint j = 0;j < customersidgroup.length;j++){
                    _address = idtousers[customersidgroup[j]].useraddress;
                    m = idtousers[customersidgroup[j]].id;
                    users[_address].plan = idtousers[m].plan;//提取申报量
                    users[_address].balance = idtousers[m].balance;//提取余额
                    for(uint l = 0; l < transactionmessagesgroup.length; l++){//记录交易编号数组
                        if(m == transactionmessagesgroup[l].producersid || m == transactionmessagesgroup[l].customersid){
                            users[_address].transactionidsgroup.push(transactionmessagesgroup[l].transactionid);
                  }
                }
                    }
                }
                else return("重复撮合");
    }
    function transactionbytype() internal {//定义名为“按类型交易”的函数
        int  x; //定义交易总量x
        int  y; //定义交易单价y//编译器版本为0.4.17
        arrangebypricefromlow(); //调用”按报价从低到高“函数
        arrangebypricefromhigh(); //调用”按报价从高到低“函数
        for(uint i = 0;i < producersidgroup.length;i++) { //循环检索数组a中类型为1的
            for(uint j = 0;j < customersidgroup.length;j++) { //循环检索数组b中类型为1的
                if (idtousers[producersidgroup[i]].price <= idtousers[customersidgroup[j]].price) { //如果生产者a[i]报价高于消费者b[i]报价，则检索下一位生产者
                    if((idtousers[producersidgroup[i]].powertype == 1)&&(idtousers[customersidgroup[j]].powertype == 1)){
                        y = (idtousers[producersidgroup[i]].price +idtousers[customersidgroup[j]].price)/2; //将生产者a[i]的报价赋给交易单价y
                        if(idtousers[producersidgroup[i]].plan > -idtousers[customersidgroup[j]].plan) { //如果生产者a[i]的申报量大于消费者b[j]的申报量
                            x = -idtousers[customersidgroup[j]].plan; //将消费者b[j]的申报量赋赋给交易量x
                            if((x*y) > idtousers[customersidgroup[j]].balance) { //当x*y大于消费者b[j]的余额时
                                x = idtousers[customersidgroup[j]].balance/y; //把消费者b[j]的余额除以交易单价赋给交易总量x
                            }
                        }
                        else { //如果生产者a[i]的申报量小于消费者b[j]的申报量
                            x = idtousers[producersidgroup[i]].plan; //将生产者a[i]的申报量赋给交易总量x
                            if((x*y) > idtousers[customersidgroup[j]].balance) { ///当x*y大于消费者b[j]的余额时
                                x = idtousers[customersidgroup[j]].balance/y; //把消费者b[j]的余额除以交易单价赋给交易总量x
                            }
                        }
                        if(x != 0) transaction(producersidgroup[i],customersidgroup[j],x,y); //调用“交易”函数，输入数据为：生产者a[i]，消费者b[j]，交易总量x，交易单价y
                    }
                }
            }
      }
        transactionbyprice(); //调用“按报价交易”函数
    }
    function transactionbyprice() internal {//定义名为“按报价交易”的函数
        int  x; //定义交易总量
        int  y; //定义交易单价
        for(uint i = 0;i < producersidgroup.length;i++) { //循环检索数组a
            for(uint j = 0;j < customersidgroup.length;j++) { //循环检索数组b
                if (idtousers[producersidgroup[i]].price <= idtousers[customersidgroup[j]].price) {//如果生产者a[i]报价高于消费者b[i]报价，则检索下一位生产者
                y = (idtousers[producersidgroup[i]].price +idtousers[customersidgroup[j]].price)/2; //将生产者a[i]的报价赋给交易单价y
                if((idtousers[producersidgroup[i]].plan) > -idtousers[customersidgroup[j]].plan) { //如果生产者a[i]的申报量大于消费者b[j]的申报量
                    x = -idtousers[customersidgroup[j]].plan; //将消费者b[j]的申报量赋赋给交易量x
                    if((x*y) > idtousers[customersidgroup[j]].balance) { //当x*y大于消费者b[j]的余额时
                        x = idtousers[customersidgroup[j]].balance/y; //把消费者b[j]的余额除以交易单价赋给交易总量x
                    }
                }
                else { //如果生产者a[i]的申报量小于消费者b[j]的申报量
                    x = idtousers[producersidgroup[i]].plan; //将生产者a[i]的申报量赋给交易总量x
                    if((x*y) > idtousers[customersidgroup[j]].balance) { //同上
                        x = idtousers[customersidgroup[j]].balance/y;
                    }
                }
                if(x != 0) transaction(producersidgroup[i],customersidgroup[j],x,y); //调用“交易”函数，输入数据为：生产者a[i]，消费者b[j]，交易总量，交易单价
              }
        }
      }
    }
    function Equilibrate() public returns(string) {//定义名为“余量平衡”的函数
      address _address;
      if(initializetransactionfeaturenumber == 1){//如果交易被执行过
          transactiontime ++;//交易周期++
          if(transactiontime == 96) transactiontime = 0;//如果交易周期等于96
              initializetransactionfeaturenumber = 0;//重置交易周期
      for(uint i = 0;i < producersidgroup.length;i++){
        _address = idtousers[producersidgroup[i]].useraddress;
            rights[_address].initializeuserfeaturenumber = 1;//初始化特征数字赋1
            int x = users[_address].pastpastplan - ammeters[_address].ammeterplan;//计算偏差电量
            users[_address].pastpastplan = users[_address].pastplan;//拷贝上一周期中标量
            users[_address].pastplan = users[_address].plancopy - users[_address].plan;//计算中标量
            if(x != 0){//如果偏差电量不为0
                equilibratenumber++;//平衡序号++
                users[_address].balance = users[_address].balance - x * s.price;//修改余额
                s.balance = s.balance + x * s.price;//修改平衡账户余额
                users[_address].equilibrateidsgroup.push(equilibratenumber);//存储余量平衡编号
                equilibratemessages[equilibratenumber].equilibratemessagetime = transactiontimecopy;//记录交易周期
                equilibratemessages[equilibratenumber].equilibrateid = equilibratenumber;//记录余量平衡编号
                equilibratemessages[equilibratenumber].equilibratename = users[_address].name;//记录用户名称
                equilibratemessages[equilibratenumber].usersid = users[_address].id;//记录用户ID
                equilibratemessages[equilibratenumber].equilibrateplan = x;//记录平衡电量
                equilibratemessages[equilibratenumber].equilibrateprice = s.price;//记录平衡电价
                s.equilibrateidsgroup.push(equilibratenumber);//记录余量平衡编号
                if(x > 0) s.positiveplan = s.positiveplan + x;//记录正平衡量
                else s.negativeplan = s.negativeplan + x;//记录负平衡量
                emit showequilibratemessage(transactiontimecopy,equilibratenumber,users[_address].name,x,s.price);//监听余量平衡
            }
            rights[_address].equilibrateright = 1;//余量平衡权限赋1
            initializeuser(_address);//初始化用户
          }
            for(uint j = 0;j < customersidgroup.length;j++){
              _address = idtousers[customersidgroup[j]].useraddress;
                  rights[_address].initializeuserfeaturenumber = 1;//初始化特征数字赋1
                  int y = users[_address].pastpastplan - ammeters[_address].ammeterplan;//计算偏差电量
                  users[_address].pastpastplan = users[_address].pastplan;//拷贝上一周期中标量
                  users[_address].pastplan = users[_address].plancopy - users[_address].plan;//计算中标量
                  if( y!= 0){//如果偏差电量不为0
                      equilibratenumber++;//平衡序号++
                      users[_address].balance = users[_address].balance - y * s.price;//修改余额
                      s.balance = s.balance + y * s.price;//修改平衡账户余额
                      users[_address].equilibrateidsgroup.push(equilibratenumber);//存储余量平衡编号
                      equilibratemessages[equilibratenumber].equilibratemessagetime = transactiontimecopy;//记录交易周期
                      equilibratemessages[equilibratenumber].equilibrateid = equilibratenumber;//记录余量平衡编号
                      equilibratemessages[equilibratenumber].equilibratename = users[_address].name;//记录用户名称
                      equilibratemessages[equilibratenumber].usersid = users[_address].id;//记录用户ID
                      equilibratemessages[equilibratenumber].equilibrateplan = y;//记录平衡电量
                      equilibratemessages[equilibratenumber].equilibrateprice = s.price;//记录平衡电价
                      s.equilibrateidsgroup.push(equilibratenumber);//记录余量平衡编号
                      if(y > 0) s.positiveplan = s.positiveplan + y;//记录正平衡量
                      else s.negativeplan = s.negativeplan + y;//记录负平衡量
                      emit showequilibratemessage(transactiontimecopy,equilibratenumber,users[_address].name,y,s.price);//监听余量平衡
                  }
                  rights[_address].equilibrateright = 1;//余量平衡权限赋1
                  initializeuser(_address);//初始化用户
      }
      return ("开始余量平衡，请稍后点击“查询按钮”查询余量平衡结果");
    }
    else return ("重复余量平衡");
    }
    function RegisterSystemaccount(int _balance) public returns(string){//平衡账户注册函数
        s.balance = _balance;//记录平衡账户余额
        systemaccountsaddress = msg.sender;//记录平衡账户地址
        return("平衡账户注册成功");
    }
    function DeclareSystemaccount(int _price) public returns(string){//平衡账户报价函数
        s.price = _price;//记录平衡账户报价
        return("平衡账户报价成功");
    }
    function GetSystemaccount() public view returns(int,int,uint,int,int){//平衡账户查询函数
        return(s.price,//公共电网电价
               s.balance,//余额
               equilibratenumber,//平衡次数
               s.positiveplan,//收购电量
               s.negativeplan);//销售电量
    }
    function GetBalance(address _address) public view returns(int){//查询用户余额
        return users[_address].balance;
    }
    function SetBalance(address _address, int _balance) public returns(string){//充值用户余额
            users[_address].balance = users[_address].balance + _balance;//充值
    }
    function GetSystemaccountBalance(address _address) public view returns(int){//查询平衡账户余额
        return systemaccounts[_address].balance;
    }
    function SetSystemaccountBalance(address _address, int _balance) public returns(string){//充值平衡账户余额
            systemaccounts[_address].balance = systemaccounts[_address].balance + _balance;//充值
            s.balance = systemaccounts[_address].balance;//记录余额
    }
    function SetTransactiontime(uint _transactiontime, uint _transactiontimecopy)public{//调整周期
        transactiontime = _transactiontime;//记录交易周期
        transactiontimecopy = _transactiontimecopy;//记录拷贝交易周期
    }
    function blockmessage() public view returns(address,uint,uint,uint,uint){//区块信息
      return(block.coinbase,//当前块的矿工的地址
             block.difficulty,//当前块的难度系数
             block.gaslimit,//当前块汽油限量
             block.number,// 当前块编号
             block.timestamp);// 当前块的时间戳
    }
}
