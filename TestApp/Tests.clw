

   MEMBER('TestApp.clw')                                   ! This is a MEMBER module

                     MAP
                       INCLUDE('TESTS.INC'),ONCE        !Local module procedure declarations
                     END


!!! <summary>
!!! Generated from procedure template - Source
!!! </summary>
Tests                PROCEDURE                             ! Declare Procedure
  MAP
AssertEqual PROCEDURE(? pExpected,? pActual,STRING pInfo),LONG,PROC
  END  

TestsResult             ANY
FilesOpened     BYTE(0)

  CODE
? DEBUGHOOK(Orders:Record)
  
  TestsResult = FORMAT(TODAY(),@D10)&' '&FORMAT(CLOCK(),@T04)
  
  DO TestGroup
  DO TestQueue 
  DO TestQueueWithSeps
  DO TestFile
  DO TestGroupWOQuotes
  DO TestGroupWPrefix
  DO TestGroupKeepPrefix
  
  DO TestDesGroupTabs
  DO TestDesGroupComas
  DO TestDesQueue
  DO TestDesFile
  DO TestDesGroupTabsKeepPrefix
  
  DO TestDesWithTitles
  DO TestDesWithAlias 
  DO TestDesOneColumn
  DO TestDesExcelFormula
  
  DO TestSaveStringToFile 
  DO TestLoadStringFromFile 

  DO TestFileFromToTextFile
  
  DO WSTest   
  
  DebugView('All tests done')
  
  !StringToFile(TestsResult,'TestsResult.txt')
  !RUN('TestsResult.txt')

TestGroup           ROUTINE  
  DATA
gr  GROUP 
Num   LONG 
Name  STRING(30),NAME('Name') 
DateTime  GROUP 
Date        DATE,NAME('Date|Attribute') 
Time        TIME 
          .
Excluded1 STRING(10) 
Name2 STRING(20)
Excluded2 STRING(10) 
Money DECIMAL(15,2) 
    END
fs  FlatSerializer
names   ANY
values  ANY
groupnv ANY
  CODE  
  
  !Arrange
  CLEAR(gr)
  gr.Num = 1234567890
  gr.Name = 'Name Abc Def'
  gr.DateTime.Date = DATE(11,28,2021)
  gr.DateTime.Time = 1+15*60*60*100+16*60*100+17*100 !15:16:17  
  gr.Excluded1 = 'Something1'
  gr.Name2 = 'Name 2 Def'
  gr.Excluded2 = 'Something2'
  gr.Money = 1234567.89
  
  !Act
  fs.Init
  fs.AddExcludedFieldByName('excluded1')  
  fs.AddExcludedFieldByReference(gr.DateTime)
  fs.AddExcludedFieldByReference(gr.Excluded2)
  names = fs.SerializeGroupNames(gr)
  values = fs.SerializeGroupValues(gr)
  groupnv = fs.SerializeGroup(gr)
  !Assert
  AssertEqual('NUM,Name,Date,TIME,NAME2,MONEY',names,'TestGroup: Group names')
  AssertEqual('1234567890,"Name Abc Def",2021-11-28,15:16:17,"Name 2 Def",1234567.89',values,'TestGroup: Group values') 
  AssertEqual('NUM,Name,Date,TIME,NAME2,MONEY<13,10>1234567890,"Name Abc Def",2021-11-28,15:16:17,"Name 2 Def",1234567.89<13,10>',groupnv,'TestGroup: Group names and values') 
  
TestQueue           ROUTINE  
  DATA
qu  QUEUE
Num   LONG
Name  STRING(30),NAME('Name')
DateTime  GROUP
Date        DATE,NAME('Date|Attribute')
Time        TIME 
          .
Excluded1 STRING(10)
Name2 STRING(20)
Excluded2 STRING(10) 
Money DECIMAL(15,2)
    END
fs  FlatSerializer
serq    ANY
  CODE  
  
  !Arrange
  CLEAR(qu)
  qu.Num = 1234567890
  qu.Name = 'Name Abc Def'
  qu.DateTime.Date = DATE(11,28,2021)
  qu.DateTime.Time = 1+15*60*60*100+16*60*100+17*100 !15:16:17  
  qu.Excluded1 = 'Something1'
  qu.Name2 = 'Name 2 Def'
  qu.Excluded2 = 'Something2'
  qu.Money = 1234567.89
  ADD(qu)
  CLEAR(qu)
  qu.Num = 2034567890
  qu.Name = '2 Name Abc Def'
  qu.DateTime.Date = DATE(11,28,2022)
  qu.DateTime.Time = 1+22*60*60*100+16*60*100+17*100 !15:16:17  
  qu.Excluded1 = 'Something21'
  qu.Name2 = '2 Name 2 Def'
  qu.Excluded2 = 'Something22'
  qu.Money = 21234567.89
  ADD(qu)
  
  !Act
  fs.Init
  fs.AddExcludedFieldByName('excluded1')  
  fs.AddExcludedFieldByReference(qu.DateTime)
  fs.AddExcludedFieldByReference(qu.Excluded2)
  serq = fs.SerializeQueue(qu)
  !Assert
  AssertEqual('NUM,Name,Date,TIME,NAME2,MONEY<13,10>1234567890,"Name Abc Def",2021-11-28,15:16:17,"Name 2 Def",1234567.89<13,10>2034567890,"2 Name Abc Def",2022-11-28,22:16:17,"2 Name 2 Def",21234567.89<13,10>',serq,'TestQueue')

TestQueueWithSeps   ROUTINE  
  DATA
qu  QUEUE
Num   LONG
Name  STRING(30),NAME('Name')
DateTime  GROUP
Date        DATE,NAME('Date|Attribute')
Time        TIME 
          .
Excluded1 STRING(10)
Name2 STRING(40)
Excluded2 STRING(10) 
Money DECIMAL(15,2)
    END
fs  FlatSerializer
serq    ANY
  CODE  
  
  !Arrange
  CLEAR(qu)
  qu.Num = 1234567890
  qu.Name = 'Name Abc 1" Def'
  qu.DateTime.Date = DATE(11,28,2021)
  qu.DateTime.Time = 1+15*60*60*100+16*60*100+17*100 !15:16:17  
  qu.Excluded1 = 'Something1'
  qu.Name2 = 'Name 2 Def'
  qu.Excluded2 = 'Something2'
  qu.Money = 1234567.89
  ADD(qu)
  CLEAR(qu)
  qu.Num = 2034567890
  qu.Name = '2 Name,Abc<13,10>Def'
  qu.DateTime.Date = DATE(11,28,2022)
  qu.DateTime.Time = 1+22*60*60*100+16*60*100+17*100 !15:16:17  
  qu.Excluded1 = 'Something21'
  qu.Name2 = '="1234567890,1234567890<13,10>1234567980"'
  qu.Excluded2 = 'Something22'
  qu.Money = 21234567.89
  ADD(qu)
  
  !Act
  fs.Init
  fs.AddExcludedFieldByName('excluded1')  
  fs.AddExcludedFieldByReference(qu.DateTime)
  fs.AddExcludedFieldByReference(qu.Excluded2)
  serq = fs.SerializeQueue(qu)
  !Assert
  AssertEqual('NUM,Name,Date,TIME,NAME2,MONEY<13,10>1234567890,"Name Abc 1"" Def",2021-11-28,15:16:17,"Name 2 Def",1234567.89<13,10>2034567890,"2 Name,Abc<13,10>Def",2022-11-28,22:16:17,="1234567890 1234567890 1234567980",21234567.89<13,10>',serq,'TestQueueWithSeps')

TestFile            ROUTINE  
  DATA
fs  FlatSerializer
serf    ANY
  CODE  
  
  !Arrange
  DO OpenFiles 

  !Act
  fs.Init
  fs.AddExcludedFieldByReference(ORD:CustOrderNumbers)
  serf = fs.SerializeFile(Orders,ORD:KeyOrderDate)
  !Assert
  AssertEqual('CUSTNUMBER,ORDERNUMBER,INVOICENUMBER,ORDERDATE,SAMENAME,SHIPTONAME,SAMEADD,SHIPADDRESS1,SHIPADDRESS2,SHIPCITY,SHIPSTATE,SHIPZIP,ORDERSHIPPED,ORDERNOTE<13,10>' & |
      '2,1,5,1996-10-10,1,"Charmaine Curry",1,"150 E. Sample Road","Suite 100","Pompano Beach","FL","33064",0,""<13,10>' & |
      '4,1,1,1996-10-10,1,"Larry Brown",1,"45 NW 35th Street","Suite 209","Boca Raton","FL","33015",0,""<13,10>' & |
      '4,2,2,1996-10-10,1,"Larry Brown",1,"45 NW 35th Street","Suite 209","Boca Raton","FL","33015",0,""<13,10>' & |
      '9,1,6,1996-10-10,1,"Harvey Henry",1,"320 Centerbury Court","Apt.23","Cincinnati","OH","45246",0,""<13,10>' & |
      '13,1,4,1996-10-10,1,"John Stoker",1,"34 Lyons Road","Apt.# 312","Margate","FL","33070",1,"Picked up by customer"<13,10>' & |
      '1,1,8,1996-10-11,1,"Carl Wright",1,"1500 E. Sample Road","Suite 302","Pompano Beach","FL","33069",0,""<13,10>' & |
      '10,1,7,1996-10-11,1,"Gloria Edwards",1,"3812 Sheppard Crossing Way","","Stone Mountain","GA","30083",0,""<13,10>' & |
      '10,2,10,1996-10-12,1,"Gloria Edwards",1,"3812 Sheppard Crossing Way","","Stone Mountain","GA","30083",0,""<13,10>' & |
      '12,1,11,1996-10-12,1,"William Zyle",1,"7831 Somerset Drive","Apt.# 210","Fort Lauderdale","FL","33012",0,""<13,10>' & |
      '14,1,9,1996-10-12,1,"Gregory King",1,"1200 S.W. 24th Avenue","Suite 109","Deerfield Beach","FL","33442",0,""<13,10>' & |
      '4,3,12,1996-10-14,1,"Larry Brown",1,"45 NW 35th Street","Suite 209","Boca Raton","FL","33015",0,""<13,10>' & |
      '3,1,16,1996-10-28,0,"Audrey Mason",0,"120 Carver Loop","Apt. 19F","Bronx","NY","10475",0,""<13,10>' & |
      '5,1,15,1996-10-28,1,"Michael Johnson",1,"45 Merry Road","Apt. # 35","Boca Raton","FL","33214",0,"Out of stock - backordered"<13,10>' & |
      '6,1,13,1996-10-28,1,"Mary Edwards",1,"67 Old England Road","Suite 29","Cooper City","FL","33034",0,""<13,10>' & |
      '7,1,17,1996-10-28,1,"Joseph Kennedy",1,"23 West Drive","","Batesville","AR","72503",0,""<13,10>' & |
      '8,1,14,1996-10-28,1,"Phillip Jacobs",1,"15 Fisher Avenue","","White Plains","NY","10606",0,""<13,10>' & |
      '11,1,18,1996-10-28,0,"Yule Brenner",0,"120 NW 15 Street","Apt.#216","Fort Lauderdale","FL","33011",0,"One item on backorder"<13,10>' & |
      '4,4,19,2003-10-29,1,"Larry Brown",1,"45 NW 35th Street","Suite 209","Boca Raton","FL","33015",0,""<13,10>',serf,'TestFile')
  
  DO CloseFiles 
  
TestGroupWOQuotes   ROUTINE  
  DATA
gr  GROUP 
Num   LONG 
Name  STRING(30),NAME('Name') 
DateTime  GROUP 
Date        DATE,NAME('Date|Attribute') 
Time        TIME 
          .
Excluded1 STRING(10) 
Name2 STRING(20)
Excluded2 STRING(10) 
Money DECIMAL(15,2) 
    END
fs  FlatSerializer
names   ANY
values  ANY
  CODE  
  
  !Arrange
  CLEAR(gr)
  gr.Num = 1234567890
  gr.Name = 'Name Abc Def'
  gr.DateTime.Date = DATE(11,28,2021)
  gr.DateTime.Time = 1+15*60*60*100+16*60*100+17*100 !15:16:17  
  gr.Excluded1 = 'Something1'
  gr.Name2 = 'Name 2"<9>Def'
  gr.Excluded2 = 'Something2'
  gr.Money = 1234567.89
  
  !Act
  fs.Init
  fs.AddExcludedFieldByName('excluded1')  
  fs.AddExcludedFieldByReference(gr.DateTime)
  fs.AddExcludedFieldByReference(gr.Excluded2)
  fs.SetAlwaysQuoteStrings(0)
  names = fs.SerializeGroupNames(gr)
  values = fs.SerializeGroupValues(gr)
  !Assert
  AssertEqual('NUM,Name,Date,TIME,NAME2,MONEY',names,'TestGroupWOQuotes Group names')
  AssertEqual('1234567890,Name Abc Def,2021-11-28,15:16:17,"Name 2""<9>Def",1234567.89',values,'TestGroupWOQuotes Group values') 
  
TestGroupWPrefix    ROUTINE  
  DATA
gr  GROUP,PRE(grx)
Num   LONG 
Name  STRING(30),NAME('Name') 
DateTime  GROUP 
Date        DATE,NAME('Date|Attribute') 
Time        TIME 
          .
Excluded1 STRING(10) 
Name2 STRING(20)
Excluded2 STRING(10) 
Money DECIMAL(15,2) 
    END
fs  FlatSerializer
names   ANY
values  ANY
groupnv ANY
  CODE  
  
  !Arrange
  CLEAR(gr)
  gr.Num = 1234567890
  gr.Name = 'Name Abc Def'
  gr.DateTime.Date = DATE(11,28,2021)
  gr.DateTime.Time = 1+15*60*60*100+16*60*100+17*100 !15:16:17  
  gr.Excluded1 = 'Something1'
  gr.Name2 = 'Name 2 Def'
  gr.Excluded2 = 'Something2'
  gr.Money = 1234567.89
  
  !Act
  fs.Init
  fs.AddExcludedFieldByName('excluded1')  
  fs.AddExcludedFieldByReference(gr.DateTime)
  fs.AddExcludedFieldByReference(gr.Excluded2)
  names = fs.SerializeGroupNames(gr)
  values = fs.SerializeGroupValues(gr)
  groupnv = fs.SerializeGroup(gr)
  !Assert
  AssertEqual('NUM,Name,Date,TIME,NAME2,MONEY',names,'TestGroupWPrefix: Group names')
  AssertEqual('1234567890,"Name Abc Def",2021-11-28,15:16:17,"Name 2 Def",1234567.89',values,'TestGroupWPrefix: Group values') 
  AssertEqual('NUM,Name,Date,TIME,NAME2,MONEY<13,10>1234567890,"Name Abc Def",2021-11-28,15:16:17,"Name 2 Def",1234567.89<13,10>',groupnv,'TestGroupWPrefix: Group names and values') 
  
TestGroupKeepPrefix ROUTINE  
  DATA
gr  GROUP,PRE(grx)
Num   LONG 
Name  STRING(30)
DateTime  GROUP 
Date        DATE
Time        TIME 
          .
Excluded1 STRING(10) 
Name2 STRING(20)
Excluded2 STRING(10) 
Money DECIMAL(15,2) 
    END
fs  FlatSerializer
names   ANY
values  ANY
groupnv ANY
  CODE  
  
  !Arrange
  CLEAR(gr)
  gr.Num = 1234567890
  gr.Name = 'Name Abc Def'
  gr.DateTime.Date = DATE(11,28,2021)
  gr.DateTime.Time = 1+15*60*60*100+16*60*100+17*100 !15:16:17  
  gr.Excluded1 = 'Something1'
  gr.Name2 = 'Name 2 Def'
  gr.Excluded2 = 'Something2'
  gr.Money = 1234567.89
  
  !Act
  fs.Init
  fs.AddExcludedFieldByName('GRX:excluded1')  
  fs.AddExcludedFieldByReference(gr.DateTime)
  fs.AddExcludedFieldByReference(gr.Excluded2)
  fs.SetRemovePrefixes(FALSE)
  names = fs.SerializeGroupNames(gr)
  values = fs.SerializeGroupValues(gr)
  groupnv = fs.SerializeGroup(gr)
  !Assert
  AssertEqual('GRX:NUM,GRX:NAME,GRX:DATE,GRX:TIME,GRX:NAME2,GRX:MONEY',names,'TestGroupKeepPrefix: Group names')
  AssertEqual('1234567890,"Name Abc Def",2021-11-28,15:16:17,"Name 2 Def",1234567.89',values,'TestGroupKeepPrefix: Group values') 
  AssertEqual('GRX:NUM,GRX:NAME,GRX:DATE,GRX:TIME,GRX:NAME2,GRX:MONEY<13,10>1234567890,"Name Abc Def",2021-11-28,15:16:17,"Name 2 Def",1234567.89<13,10>',groupnv,'TestGroupKeepPrefix: Group names and values') 


TestDesGroupTabs    ROUTINE  
  DATA
gr  GROUP 
Num   LONG 
Name  STRING(30),NAME('Name') 
DateTime  GROUP 
Date        DATE,NAME('Date|Attribute') 
Time        TIME 
          .
Excluded1 STRING(10) 
Name2 STRING(20)
Excluded2 STRING(10) 
Money DECIMAL(15,2) 
    END
fs  FlatSerializer
names   ANY
values  ANY
  CODE  
  
  !Arrange
  CLEAR(gr)
  
  fs.InitTSV
  fs.LoadString('NUM<9>Name<9>Date<9>TIME<9>NAME2<9>MONEY<13,10>1234567890<9>"Name Abc 1"" Def"<9>2021-11-28<9>15:16:17<9>"Name"""" 2 Def"""""<9>1234567.89')

  !Act
  fs.DeSerializeToGroup(gr)
  
  
  !Assert      
  AssertEqual('1234567890',gr.Num,'TestDesGroup')
  AssertEqual('Name Abc 1" Def',gr.Name,'TestDesGroup')
  AssertEqual(DATE(11,28,2021),gr.DateTime.Date,'TestDesGroup')
  AssertEqual(1+15*60*60*100+16*60*100+17*100,gr.DateTime.Time,'TestDesGroup')
  AssertEqual('Name"" 2 Def""',gr.Name2,'TestDesGroup')
  AssertEqual('1234567.89',gr.Money,'TestDesGroup')
  AssertEqual('Name"" 2 Def""',fs.GetValueByName('Name2'),'TestDesGroup')

TestDesGroupComas   ROUTINE  
  DATA
gr  GROUP 
Num   LONG 
Name  STRING(30),NAME('Name') 
DateTime  GROUP 
Date        DATE,NAME('Date|Attribute') 
Time        TIME 
          .
Excluded1 STRING(10) 
Name2 STRING(20)
Excluded2 STRING(10) 
Money DECIMAL(15,2) 
    END
fs  FlatSerializer
names   ANY
values  ANY
  CODE  
  
  !Arrange
  CLEAR(gr)
  
  fs.Init  
  fs.LoadString('NUM,Name,Date,TIME,NAME2,MONEY<13,10>1234567890,"Name, Abc 1"" Def",2021-11-28,15:16:17,"Name"""" 2 Def""""",1234567.89')
  
  !Act
  fs.DeSerializeToGroup(gr)
  
  
  !Assert      
  AssertEqual('1234567890',gr.Num,'TestDesGroup')
  AssertEqual('Name, Abc 1" Def',gr.Name,'TestDesGroup')
  AssertEqual(DATE(11,28,2021),gr.DateTime.Date,'TestDesGroup')
  AssertEqual(1+15*60*60*100+16*60*100+17*100,gr.DateTime.Time,'TestDesGroup')
  AssertEqual('Name"" 2 Def""',gr.Name2,'TestDesGroup')
  AssertEqual('1234567.89',gr.Money,'TestDesGroup')
  AssertEqual('Name"" 2 Def""',fs.GetValueByName('Name2'),'TestDesGroup')

TestDesQueue        ROUTINE  
  DATA
qu  QUEUE
Num   LONG
Name  STRING(30),NAME('Name')
DateTime  GROUP
Date        DATE,NAME('Date|Attribute')
Time        TIME 
          .
Excluded1 STRING(10)
Name2 STRING(20)
Excluded2 STRING(10) 
Money DECIMAL(15,2)
    END
fs  FlatSerializer
serq    ANY
  CODE  
  
  !Arrange
  FREE(qu)  
  
  !Act
  fs.InitTSV
  fs.LoadString('NUM<9>Name<9>Date<9>TIME<9>NAME2<9>MONEY<13,10>1234567890<9>"Name Abc Def"<9>2021-11-28<9>15:16:17<9>"Name 2 Def"<9>1234567.89<13,10>2034567890<9>"2 Name Abc Def"<9>2022-11-28<9>22:16:17<9>"2 Name 2 Def"<9>21234567.89')
  fs.DeserializeToQueue(qu)
  
  !Assert    
  AssertEqual(2,RECORDS(qu),'TestDesQueue')
  GET(qu,2)
  
  AssertEqual('2034567890',qu.Num,'TestDesQueue')
  AssertEqual('2 Name Abc Def',qu.Name,'TestDesQueue')
  AssertEqual(DATE(11,28,2022),qu.DateTime.Date,'TestDesQueue')
  AssertEqual(1+22*60*60*100+16*60*100+17*100,qu.DateTime.Time,'TestDesQueue')
  AssertEqual('2 Name 2 Def',qu.Name2,'TestDesQueue')
  AssertEqual(21234567.89,qu.Money,'TestDesQueue')
  AssertEqual('2 Name 2 Def',fs.GetValueByName('Name2',2),'TestDesQueue')
  
  
TestDesFile         ROUTINE  
  DATA
fs  FlatSerializer
serf    ANY
  CODE  
  
  !Arrange
  Orders{PROP:Name} = 'ORDERS.TMP'
  CREATE(Orders)  
  DO OpenFiles 

  !Act
  fs.InitTSV
  fs.AddExcludedFieldByReference(ORD:CustOrderNumbers)
  fs.LoadString('CUSTNUMBER<9>ORDERNUMBER<9>INVOICENUMBER<9>ORDERDATE<9>SAMENAME<9>SHIPTONAME<9>SAMEADD<9>SHIPADDRESS1<9>SHIPADDRESS2<9>SHIPCITY<9>SHIPSTATE<9>SHIPZIP<9>ORDERSHIPPED<9>ORDERNOTE<13,10>' & |
      '2<9>1<9>5<9>1996-10-10<9>1<9>"Charmaine Curry"<9>1<9>"150 E. Sample Road"<9>"Suite 100"<9>"Pompano Beach"<9>"FL"<9>"33064"<9>0<9>""<13,10>' & |
      'EMPTY LINE<13,10>' & |
      '4<9>1<9>1<9>1996-10-10<9>1<9>"Larry Brown"<9>1<9>"45 NW 35th Street"<9>"Suite 209"<9>"Boca Raton"<9>"FL"<9>"33015"<9>0<9>""<13,10>')    
  fs.DeSerializeToFile(Orders)
  
  !Assert
  CLEAR(ORD:Record)
  SET(ORD:KeyOrderDate)
  NEXT(Orders)
  NEXT(Orders)
  
  AssertEqual(4,ORD:CustNumber,'TestDesFile')
  AssertEqual(1,ORD:OrderNumber,'TestDesFile')
  AssertEqual(1,ORD:InvoiceNumber,'TestDesFile')
  AssertEqual(DATE(10,10,1996),ORD:OrderDate,'TestDesFile')
  AssertEqual(4,ORD:CustNumber,'TestDesFile')
  AssertEqual('Larry Brown',ORD:ShipToName,'TestDesFile')
  
  DO CloseFiles 
  REMOVE('ORDERS.TMP')
  
TestDesGroupTabsKeepPrefix  ROUTINE  
  DATA
gr  GROUP,PRE(GRX)
Num   LONG 
Name  STRING(30)
DateTime  GROUP 
Date        DATE
Time        TIME 
          .
Excluded1 STRING(10) 
Name2 STRING(20)
Excluded2 STRING(10) 
Money DECIMAL(15,2) 
    END
fs  FlatSerializer
names   ANY
values  ANY
  CODE  
  
  !Arrange
  CLEAR(gr)
  
  fs.InitTSV
  fs.SetRemovePrefixes(FALSE)
  fs.LoadString('GRX:NUM<9>GRX:Name<9>GRX:Date<9>GRX:TIME<9>GRX:NAME2<9>GRX:MONEY<13,10>1234567890<9>"Name Abc 1"" Def"<9>2021-11-28<9>15:16:17<9>"Name"""" 2 Def"""""<9>1234567.89')

  !Act
  fs.DeSerializeToGroup(gr)
  
  
  !Assert      
  AssertEqual('1234567890',gr.Num,'TestDesGroupTabsKeepPrefix')
  AssertEqual('Name Abc 1" Def',gr.Name,'TestDesGroupTabsKeepPrefix')
  AssertEqual(DATE(11,28,2021),gr.DateTime.Date,'TestDesGroupTabsKeepPrefix')
  AssertEqual(1+15*60*60*100+16*60*100+17*100,gr.DateTime.Time,'TestDesGroupTabsKeepPrefix')
  AssertEqual('Name"" 2 Def""',gr.Name2,'TestDesGroupTabsKeepPrefix')
  AssertEqual('1234567.89',gr.Money,'TestDesGroupTabsKeepPrefix')
  AssertEqual('Name"" 2 Def""',fs.GetValueByName('GRX:Name2'),'TestDesGroupTabsKeepPrefix') 

TestDesWithTitles   ROUTINE  
  DATA
gr  GROUP 
Num   LONG 
Name  STRING(30),NAME('Name') 
DateTime  GROUP 
Date        DATE,NAME('Date|Attribute') 
Time        TIME 
          .
Excluded1 STRING(10) 
Name2 STRING(20)
Excluded2 STRING(10) 
Money DECIMAL(15,2) 
    END
fs  FlatSerializer
names   ANY
values  ANY
  CODE  
  
  !Arrange
  CLEAR(gr)
  
  fs.InitTSV
  fs.LoadString('This is a CSV String with titles<13,10>Line 2<13,10,13,10>NUM<9>Name<9>Date<9>TIME<9>NAME2<9>MONEY<13,10>1234567890<9>"Name Abc 1"" Def"<9>2021-11-28<9>15:16:17<9>"Name"""" 2 Def"""""<9>1234567.89')

  !Act
  fs.DeSerializeToGroup(gr)  
  
  !Assert      
  AssertEqual('1234567890',gr.Num,'TestDesWithTitles')
  AssertEqual('Name Abc 1" Def',gr.Name,'TestDesWithTitles')
  AssertEqual(DATE(11,28,2021),gr.DateTime.Date,'TestDesWithTitles')
  AssertEqual(1+15*60*60*100+16*60*100+17*100,gr.DateTime.Time,'TestDesWithTitles')
  AssertEqual('Name"" 2 Def""',gr.Name2,'TestDesWithTitles')
  AssertEqual('1234567.89',gr.Money,'TestDesWithTitles')
  AssertEqual('Name"" 2 Def""',fs.GetValueByName('Name2'),'TestDesWithTitles')

TestDesWithAlias    ROUTINE  
  DATA
gr  GROUP 
Num   LONG 
Name  STRING(30),NAME('Name') 
DateTime  GROUP 
Date        DATE,NAME('Date|Attribute') 
Time        TIME 
          .
Excluded1 STRING(10) 
Name2 STRING(20)
Excluded2 STRING(10) 
Money DECIMAL(15,2) 
    END
fs  FlatSerializer
names   ANY
values  ANY
  CODE  
  
  !Arrange
  CLEAR(gr)
  
  fs.InitTSV
  fs.AddFieldAliasByReference(gr.Name,'This is a Name')
  fs.LoadString('NUM<9>This is a Name<9>Date<9>TIME<9>NAME2<9>MONEY<13,10>1234567890<9>"Name Abc 1"" Def"<9>2021-11-28<9>15:16:17<9>"Name"""" 2 Def"""""<9>1234567.89')

  !Act
  fs.DeSerializeToGroup(gr)
  
  
  !Assert      
  AssertEqual('1234567890',gr.Num,'TestDesWithAlias')
  AssertEqual('Name Abc 1" Def',gr.Name,'TestDesWithAlias')
  AssertEqual(DATE(11,28,2021),gr.DateTime.Date,'TestDesWithAlias')
  AssertEqual(1+15*60*60*100+16*60*100+17*100,gr.DateTime.Time,'TestDesWithAlias')
  AssertEqual('Name"" 2 Def""',gr.Name2,'TestDesWithAlias')
  AssertEqual('1234567.89',gr.Money,'TestDesWithAlias')
  AssertEqual('Name"" 2 Def""',fs.GetValueByName('Name2'),'TestDesWithAlias')
  
TestDesOneColumn    ROUTINE
  DATA
gr  GROUP 
Name  STRING(30),NAME('Name') 
    END
fs  FlatSerializer
  CODE  
  
  !Arrange
  CLEAR(gr)
  
  fs.Init  
  fs.SetReadLinesWithoutColumnSeparators(TRUE)
  fs.LoadString('Name<13,10>One Name')

  !Act
  fs.DeSerializeToGroup(gr)  
  
  !Assert      
  AssertEqual('One Name',gr.Name,'TestDesOneColumn')  
  
TestDesExcelFormula ROUTINE  
  
  DATA
gr  GROUP 
NUM   LONG
Name  STRING(60)
BigNumber DECIMAL(24,2)
NameWithDash  STRING(60)
Name2 STRING(40)
Number2   LONG
    END
fs  FlatSerializer
names   ANY
values  ANY
bignum  DECIMAL(24,2)
  CODE  
  
  !Arrange
  CLEAR(gr)
  
  fs.InitTSV
  fs.LoadString('NUM<9>NAME<9>BIGNUMBER<9>NAMEWITHDASH<9>NAME2<9>NUMBER2<13,10>' & | 
      '1234<9>="This is an Excel string<9>formula""constant"<9>12345679801234567980.12<9>="1234-12-23"<9>Some "" name<9>22222')
  bignum = 12345679801234567980.12
  !Act
  fs.DeSerializeToGroup(gr)
  
  
  !Assert      
  AssertEqual('1234',gr.Num,'TestDesExcelFormula')
  AssertEqual('This is an Excel string<9>formula"constant',gr.Name,'TestDesExcelFormula')
  AssertEqual(FORMAT(bignum,@N_24.2),FORMAT(gr.BigNumber,@N_24.2),'TestDesExcelFormula')
  AssertEqual('1234-12-23',gr.NameWithDash,'TestDesExcelFormula')
  AssertEqual('Some " name',gr.Name2,'TestDesExcelFormula')
  AssertEqual(22222,gr.Number2,'TestDesExcelFormula')
  
TestSaveStringToFile    ROUTINE
  DATA
fs  FlatSerializer
qf  QUEUE(FILE:queue)
    END
i   LONG
  CODE
  
  !Arrange
  
  !Act
  fs.StringToTextFile('','file000000.txt')
  fs.StringToTextFile('1','file000001.txt')
  fs.StringToTextFile('1<13,10>','file000003.txt')
  fs.StringToTextFile(ALL('*',10000),'file010000.txt')
  fs.StringToTextFile(ALL('*',32767),'file032767.txt')
  fs.StringToTextFile(ALL('*',32768),'file032768.txt')
  fs.StringToTextFile(ALL('*',32769),'file032769.txt')
  fs.StringToTextFile(ALL('*',100000),'file100000.txt')
 
  !Assert
  AssertEqual('0',ERRORCODE()&' '&ERROR()&' '&ERRORFILE(),'TestSaveStringToFile')
  
  DIRECTORY(qf,'file*.txt',ff_:NORMAL)
  LOOP i = 1 TO RECORDS(qf)
    GET(qf,i) 
    AssertEqual(SUB(qf.Name,5,6)+0,qf.Size,'TestSaveStringToFile')
    !Cleanup
    REMOVE(qf.Name)
  .
  
TestLoadStringFromFile  ROUTINE
  DATA
fs  FlatSerializer
str0    ANY
str1    ANY
str3    ANY
str10000    ANY
str32767    ANY
str32768    ANY
str32769    ANY
str100000   ANY
  CODE
  
  !Arrange  
  fs.StringToTextFile('','file000000.txt')
  fs.StringToTextFile('1','file000001.txt')
  fs.StringToTextFile('1<13,10>','file000003.txt')
  fs.StringToTextFile(ALL('*',10000),'file010000.txt')
  fs.StringToTextFile(ALL('*',32767),'file032767.txt')
  fs.StringToTextFile(ALL('*',32768),'file032768.txt')
  fs.StringToTextFile(ALL('*',32769),'file032769.txt')
  fs.StringToTextFile(ALL('*',100000),'file100000.txt')
  
  !Act
  str0 = fs.StringFromTextFile('file000000.txt')
  str1 = fs.StringFromTextFile('file000001.txt')
  str3 = fs.StringFromTextFile('file000003.txt')
  str10000 = fs.StringFromTextFile('file010000.txt')
  str32767 = fs.StringFromTextFile('file032767.txt')
  str32768 = fs.StringFromTextFile('file032768.txt')
  str32769 = fs.StringFromTextFile('file032769.txt')
  str100000 = fs.StringFromTextFile('file100000.txt')  

 
  !Assert
  AssertEqual('0',ERRORCODE()&' '&ERROR()&' '&ERRORFILE(),'TestLoadStringFromFile')
  AssertEqual('',str0,'TestLoadStringFromFile')
  AssertEqual(0,LEN(str0),'TestLoadStringFromFile')
  AssertEqual('1',str1,'TestLoadStringFromFile')
  AssertEqual(1,LEN(str1),'TestLoadStringFromFile')
  AssertEqual('1<13,10>',str3,'TestLoadStringFromFile')
  AssertEqual(3,LEN(str3),'TestLoadStringFromFile')
  AssertEqual( '* ',SUB(str10000,10000,2),'TestLoadStringFromFile')
  AssertEqual(10000,LEN(str10000),'TestLoadStringFromFile')
  AssertEqual( '*  ',SUB(str32767,32767,3),'TestLoadStringFromFile')
  AssertEqual(32767,LEN(str32767),'TestLoadStringFromFile')
  AssertEqual( '** ',SUB(str32768,32767,3),'TestLoadStringFromFile')
  AssertEqual(32768,LEN(str32768),'TestLoadStringFromFile')
  AssertEqual( '***',SUB(str32769,32767,3),'TestLoadStringFromFile')
  AssertEqual(32769,LEN(str32769),'TestLoadStringFromFile')    
  AssertEqual( '* ',SUB(str100000,100000,2),'TestLoadStringFromFile')
  AssertEqual(100000,LEN(str100000),'TestLoadStringFromFile')  
  
  !Cleanup
  REMOVE('file000000.txt')
  REMOVE('file000001.txt')
  REMOVE('file000003.txt')
  REMOVE('file010000.txt')
  REMOVE('file032767.txt')
  REMOVE('file032768.txt')
  REMOVE('file032769.txt')
  REMOVE('file100000.txt')  

  
TestFileFromToTextFile  ROUTINE  
  DATA
fs  FlatSerializer
serf    ANY
serf2   ANY
  CODE  
  
  !Arrange
  Orders{PROP:Name} = 'ORDERS.TMP'
  CREATE(Orders)  
  DO OpenFiles   
  
  serf = 'CUSTNUMBER<9>ORDERNUMBER<9>INVOICENUMBER<9>ORDERDATE<9>SAMENAME<9>SHIPTONAME<9>SAMEADD<9>SHIPADDRESS1<9>SHIPADDRESS2<9>SHIPCITY<9>SHIPSTATE<9>SHIPZIP<9>ORDERSHIPPED<9>ORDERNOTE<13,10>' & |
      '2<9>1<9>5<9>1996-10-10<9>1<9>Charmaine Curry<9>1<9>150 E. Sample Road<9>Suite 100<9>Pompano Beach<9>FL<9>33064<9>0<9><13,10>' & |
      '4<9>1<9>1<9>1996-10-10<9>1<9>Larry Brown<9>1<9>45 NW 35th Street<9>Suite 209<9>Boca Raton<9>FL<9>33015<9>0<9><13,10>'
  
  fs.StringToTextFile(serf,'testfile.txt')  

  !Act
  fs.InitTSV
  fs.LoadTextFile('testfile.txt')
  fs.DeSerializeToFile(Orders)
  
  !Assert
  CLEAR(ORD:Record)
  SET(ORD:KeyOrderDate)
  NEXT(Orders)
  NEXT(Orders)
  
  AssertEqual(4,ORD:CustNumber,'TestFileFromToTextFile')
  AssertEqual(1,ORD:OrderNumber,'TestFileFromToTextFile')
  AssertEqual(1,ORD:InvoiceNumber,'TestFileFromToTextFile')
  AssertEqual(DATE(10,10,1996),ORD:OrderDate,'TestFileFromToTextFile')
  AssertEqual(4,ORD:CustNumber,'TestFileFromToTextFile')
  AssertEqual('Larry Brown',ORD:ShipToName,'TestFileFromToTextFile')
  
  fs.InitTSV
  fs.AddExcludedFieldByReference(ORD:CustOrderNumbers)  
  fs.SerializeFileToTextFile(Orders,'testfile2.txt')  
  
  serf2 = fs.StringFromTextFile('testfile2.txt')
  
  AssertEqual(serf,serf2,'TestFileFromToTextFile')
  
  DO CloseFiles 
  
  !Cleanup      
  REMOVE('ORDERS.TMP')
  REMOVE('testfile.txt')
  REMOVE('testfile2.txt')

WSTest              ROUTINE     
  DATA
LotePagosList   QUEUE,PRE(LPAL)                       !
Proveedor         LONG,NAME('Proveedor')                !
Nombre            STRING(80),NAME('Nombre')             !
Folio             STRING(40),NAME('Folio')              !
Letra             STRING(10),NAME('Letra')              !
FechaFactura      DATE,NAME('FechaFactura')             !
FechaRecibida     DATE,NAME('FechaRecibida')            !
FechaVencimiento  DATE,NAME('FechaVencimiento')         !
FechaProcesoLote  DATE,NAME('FechaProcesoLote')         !
Obs               STRING(200),NAME('Obs')               !
PagoFactura       DECIMAL(15,2),NAME('PagoFactura')     !
APagarLote        DECIMAL(15,2),NAME('APagarLote')      !
DatosPoliza       STRING(200),NAME('DatosPoliza')       !
Cuenta            STRING(30),NAME('Cuenta')             !
NombreCuenta      STRING(100),NAME('NombreCuenta')      !
DivN1             LONG,NAME('DivN1')                    !
DivN2             LONG,NAME('DivN2')                    !
Concepto          STRING(100),NAME('Concepto')          !
Cargo             DECIMAL(15,2),NAME('Cargo')           !
Abono             DECIMAL(15,2),NAME('Abono')           !
                END                        
fs  FlatSerializer
txt STRING('TITLE TEXT<13,10>'&|
        'Subttile Text<13,10>'&|
        'Info Text: 123456<13,10>'&|
        '<13,10>'&|
        'Proveedor<9>Nombre<9>Folio<9>Letra<9>F.Fac.<9>F.Rec.<9>F.Ven.<9>F.Pro.<9>Obs.<9>Pago<9>A Pagar<9>Póliza<9>Cuenta<9>Nombre Cuenta<9>CC<9><9>Concepto<9>Cargo<9>Abono<13,10>'&|
        '213165<9>NAME ABC S DE RL DE CV<9><9><9>27-AGO-21<9><9><9><9><9><9>631.8<9>M:9 D:40 P:24493 30-SEP-21 NAME ABC S DE RL DE CV<13,10>'&|
        '<9><9><9><9><9><9><9><9><9><9><9><9>="1120-006"<9>HSBC 40-24292609 Mn<9><9><9>98771<9><9>631.8<13,10>'&|
        '<9><9><9><9><9><9><9><9><9><9><9><9>="6053-000"<9>UNIFORMES Y EQ. DE SEGURIDAD<9>240<9><9>NAME ABC S DE RL DE CV S DE RL DE CV<9>585<9><13,10>'&|
        '<9><9><9><9><9><9><9><9><9><9><9><9>="1160-008"<9>Iva Provisionado 8%<9><9><9>NAME ABC S DE RL DE CV S DE RL DE CV<9>46.8<9><13,10>'&|
        '<9><9><9><9><9><9><9><9><9><9><9><9>="1160-008"<9>Iva Provisionado 8%<9><9><9>NAME ABC S DE RL DE CV S DE RL DE CV<9><9>46.8<13,10>'&|
        '<9><9><9><9><9><9><9><9><9><9><9><9>="1160-018"<9>IVA Acred 8% S/gts y Cpras<9><9><9>NAME ABC S DE RL DE CV S DE RL DE CV<9>46.8<9><13,10>'&|
        '<13,10>'&|
        '<9>Total del Lote:<9><9><9><9><9><9><9><9><9>113910.54<13,10>')

  CODE  
  
  !Arrange
  LOCALE('CLAMON','Ene,Feb,Mar,Abr,May,Jun,Jul,Ago,Sep,Oct,Nov,Dic')
  fs.InitTSV
  fs.SetDatesPicture('@D7-')
  fs.AddFieldAliasByReference(LotePagosList.Proveedor,'Proveedor')
  fs.AddFieldAliasByReference(LotePagosList.Nombre,'Nombre')
  fs.AddFieldAliasByReference(LotePagosList.Folio,'Folio')
  fs.AddFieldAliasByReference(LotePagosList.Letra,'Letra')
  fs.AddFieldAliasByReference(LotePagosList.FechaFactura,'F.Fac.')
  fs.AddFieldAliasByReference(LotePagosList.FechaRecibida,'F.Rec.')
  fs.AddFieldAliasByReference(LotePagosList.FechaVencimiento,'F.Ven.')
  fs.AddFieldAliasByReference(LotePagosList.FechaProcesoLote,'F.Pro.')
  fs.AddFieldAliasByReference(LotePagosList.Obs,'Obs.')
  fs.AddFieldAliasByReference(LotePagosList.PagoFactura,'Pago')
  fs.AddFieldAliasByReference(LotePagosList.APagarLote,'A Pagar	')
  fs.AddFieldAliasByReference(LotePagosList.DatosPoliza,'Póliza')
  fs.AddFieldAliasByReference(LotePagosList.Cuenta,'Cuenta')
  fs.AddFieldAliasByReference(LotePagosList.NombreCuenta,'Nombre Cuenta')
  fs.AddFieldAliasByReference(LotePagosList.DivN1,'CC')
  fs.AddFieldAliasByReference(LotePagosList.Concepto,'Concepto')
  fs.AddFieldAliasByReference(LotePagosList.Cargo,'Cargo')
  fs.AddFieldAliasByReference(LotePagosList.Abono,'Abono')
  
  !Act
  fs.LoadString(txt)
  fs.DeserializeToQueue(LotePagosList)  
  
  !Assert      
  GET(LotePagosList,1)
  AssertEqual('M:9 D:40 P:24493 30-SEP-21 NAME ABC S DE RL DE CV',CLIP(LotePagosList.DatosPoliza),'WSTest')
  AssertEqual(FORMAT(DATE(8,27,21),@D10),FORMAT(LotePagosList.FechaFactura,@D10),'WSTest')
!--------------------------------------
OpenFiles  ROUTINE
  Access:Orders.Open()                                     ! Open File referenced in 'Other Files' so need to inform it's FileManager
  Access:Orders.UseFile()                                  ! Use File referenced in 'Other Files' so need to inform it's FileManager
  FilesOpened = True
!--------------------------------------
CloseFiles ROUTINE
  IF FilesOpened THEN
     Access:Orders.Close()
     FilesOpened = False
  END

AssertEqual         PROCEDURE(? pExpected,? pActual,STRING pInfo)!,LONG,PROC
TestResult ANY
  CODE 
  
  TestResult = CHOOSE(pExpected = pActual,'ok','--')&'<9>'& |
      pInfo&'<13,10>' & |
      'Exp: <'&pExpected&'>'&'<13,10>'& |
      'Act: <'&pActual&'>' & |
      '<13,10>'
  
  DebugView(TestResult)
  
  IF pExpected <> pActual THEN 
    SETCLIPBOARD(TestResult)
    STOP(TestResult)
  .
  
  TestsResult =  CHOOSE(TestsResult = '','',TestsResult&'<13,10>')& |         
      TestResult  
  
  RETURN CHOOSE(pExpected = pActual)
    
