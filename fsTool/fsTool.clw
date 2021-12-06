  PROGRAM

  INCLUDE('FlatSerializer.inc'),ONCE

  MAP
  END


filename            STRING(FILE:MaxFileName)
fs                  FlatSerializer
txt                 ANY

LOC:Label           PSTRING(100)
LOC:Pre             PSTRING(10)
LOC:Obj             PSTRING(10)
LOC:ReadClipboard   BOOL

crlf                STRING('<13,10>')


  CODE
  
  LOOP 
    EXECUTE POPUP( |
        'Read CSV file|' & |
        'Read TSV file|' & |
        'Queue and alias from file to clipboard|' & |
        'Queue and alias from/to clipboard|' & |
        'Exit')
      DO ReadCsvFile
      DO ReadTsvFile
      DO QueueAliasFile
      DO QueueAliasClipboard
    ELSE      
      RETURN
    END
  END
  
ReadCsvFile         ROUTINE  

  IF FILEDIALOG('CSV File',filename,'CSV File(*.txt,*.csv)|*.txt;*.csv',FILE:KeepDir+FILE:LongName+FILE:AddExtension)
    fs.Init
    fs.LoadTextFile(filename)
  .  
  DO ShowFile 
  
ReadTsvFile         ROUTINE  

  IF FILEDIALOG('TSV File',filename,'TSV File(*.txt,*.tsv)|*.txt;*.tsv',FILE:KeepDir+FILE:LongName+FILE:AddExtension)
    fs.InitTSV
    fs.LoadTextFile(filename)
  .  
  DO ShowFile 
  
ShowFile            ROUTINE
  DATA 
idx LONG 
  CODE
  
  txt = ''
  txt = txt & 'Columns: '& fs.GetColumnsCount()
  txt = txt & crlf
  txt = txt & crlf
  txt = txt & 'Lines: '& fs.GetLinesCount()
  txt = txt & crlf
  txt = txt & crlf
  txt = txt & 'Headers:'
  txt = txt & crlf
  LOOP idx = 1 TO fs.GetColumnsCount()
    txt = txt & fs.GetColumnName(idx) & crlf
  .
  txt = txt & crlf
  txt = txt & crlf
  txt = txt & 'First line:'
  txt = txt & crlf
  LOOP idx = 1 TO fs.GetColumnsCount()
    txt = txt & fs.GetValueByName(fs.GetColumnName(idx),1,fs:DeformatNothing) & crlf
  .  
  txt = txt & crlf
  txt = txt & crlf
  txt = txt & 'Last line:'
  txt = txt & crlf
  LOOP idx = 1 TO fs.GetColumnsCount()
    txt = txt & fs.GetValueByName(fs.GetColumnName(idx),fs.GetLinesCount(),fs:DeformatNothing) & crlf
  .
  txt = txt & crlf
  MESSAGE(txt)
  
QueueAliasFile      ROUTINE  
  
  IF FILEDIALOG('CSV/TST File',filename,'CSV/TST File(*.txt,*.csv,*.tsv)|*.txt;*.csv;*.tsv',FILE:KeepDir+FILE:LongName+FILE:AddExtension)
    txt = fs.StringFromTextFile(filename)
  .
  LOC:ReadClipboard = FALSE
  DO QueueDeclarationWindow
  
QueueAliasClipboard ROUTINE   

  LOC:ReadClipboard = TRUE
  DO QueueDeclarationWindow

QueueDeclarationWindow ROUTINE   

  DATA
Window  WINDOW('Queue and alias'),AT(,,254,256),SYSTEM,FONT('Segoe UI',9)
          PROMPT('Queue label:'),AT(4,4),USE(?label)
          ENTRY(@S100),AT(46,4,118,10),USE(LOC:Label),REQ
          PROMPT('Prefix:'),AT(168,4),USE(?pre)
          ENTRY(@S20),AT(193,4,55,10),USE(LOC:Pre)
          PROMPT('fs object:'),AT(4,16),USE(?obj)
          ENTRY(@S20),AT(46,16,56,10),USE(LOC:Obj),REQ
          BUTTON('Go'),AT(217,16,,11),USE(?Go),REQ
          TEXT,AT(4,31,245,220),USE(?text),FONT('Consolas',8)
        END
  CODE  
  
  LOC:Label = 'myQ'
  LOC:Obj = 'fs'
  OPEN(Window)
  IF LOC:ReadClipboard
    ?text{PROP:Text} = CLIPBOARD()
  ELSE
    ?text{PROP:Text} = txt
  .  
  ACCEPT
    CASE EVENT()
      OF EVENT:GainFocus
        IF LOC:ReadClipboard
          ?text{PROP:Text} = CLIPBOARD()
        .        
      OF EVENT:Accepted
        IF ACCEPTED() = ?Go
          txt = ?text{PROP:Text}
          DO CreateQueueDeclaration
          ?text{PROP:Text} = txt
          SETCLIPBOARD(txt)
          MESSAGE('Code copied to clipboard')   
        .
    END
  END  
  
CreateQueueDeclaration  ROUTINE  
  DATA
idxc    LONG
idxl    LONG
value   ANY
intvalue    LONG
idx LONG 
qField  QUEUE
Name      PSTRING(100)
Label     PSTRING(100)
Length    LONG
String    BOOL
Numeric   BOOL
Decimals  BOOL
Date      BOOL
Time      BOOL
        END
ReplaceLabel    STRING('·È˙Û˙¸¡…Õ”⁄‹Ò—')
ReplaceWith STRING('aeiouuAEIOUUnN')
pos LONG
isTsv   LONG
  CODE

  isTsv = INSTRING('<9>',SUB(txt,1,300),1,1)    
  
  IF isTsv
    fs.InitTSV
  ELSE
    fs.Init
  .
  !Defaults, change if file uses different date/time pictures
  !fs.SetDatesPicture('@D10-B')
  !fs.SetTimesPicture('@T04B')
  fs.LoadString(txt)
  
  !Create queue with columns, label and value type
  LOOP idxc = 1 TO fs.GetColumnsCount()
    CLEAR(qField)
    qField.Name = fs.GetColumnName(idxc)
    !Create valid Clarion label
    LOOP idx = 1 TO LEN(qField.Name)
      IF INRANGE(VAL(UPPER(qField.Name[idx])),VAL('A'),VAL('Z')) OR INRANGE(VAL(qField.Name[idx]),VAL('0'),VAL('9')) OR INLIST(qField.Name[idx],':','_')
        qField.Label = qField.Label & qField.Name[idx]
      ELSE
        pos = INSTRING(qField.Name[idx],ReplaceLabel,1,1)
        IF pos 
          qField.Label = qField.Label & ReplaceWith[pos]
          !ELSE
          !  qField.Label = qField.Label & '_'
        .        
      .      
    .
    IF NUMERIC(qField.Label[1]) 
      qField.Label = 'n' & qField.Label
    .
    !Check length and type of values of this column, first 20 records
    LOOP idxl = 1 TO fs.GetLinesCount()
      IF idxl > 20 THEN BREAK.
      value = fs.GetValueByName(fs.GetColumnName(idxc),idxl,fs:DeformatNothing)      
      IF LEN(value) > qField.Length
        qField.Length = LEN(value)
      .
      IF value AND NOT NUMERIC(value)
        qField.String = TRUE
        qField.Decimals = 0
      .
      !Test for dates and times      
      intvalue = DEFORMAT(value,fs.GetDatesPicture())
      IF intvalue AND CLIP(LEFT(FORMAT(intvalue,fs.GetDatesPicture()))) = CLIP(LEFT(value))
        qField.Date = TRUE
      .      
      intvalue = DEFORMAT(value,fs.GetTimesPicture())
      IF intvalue AND CLIP(LEFT(FORMAT(intvalue,fs.GetTimesPicture()))) = CLIP(LEFT(value))
        qField.Time = TRUE
      .      
      IF NOT qField.String
        IF value+0 <> INT(value+0)
          qField.Decimals = TRUE
        .
      .
    .
    ADD(qField)
  .

  !Create queue declaration 
  txt = LOC:Label & ' QUEUE'
  IF LOC:Pre
    txt = txt & ',PRE(' & LOC:Pre & ')'
  .
  txt = txt & crlf
  LOOP idxc = 1 TO RECORDS(qField)
    GET(qField,idxc)
    txt = txt & qField.Label
    IF qField.Date
      txt = txt & ' DATE'      
    ELSIF qField.Time
      txt = txt & ' TIME'      
    ELSIF qField.Decimals
      txt = txt & ' DECIMAL(15,2)'
    ELSIF NOT qField.String
      txt = txt & ' LONG'
    ELSE
      txt = txt & ' STRING(' & ROUND(qField.Length+5,10) & ')'
    .
    txt = txt & ',NAME(''' & qField.Label & | 
        CHOOSE(qField.Date = TRUE,' | ' & fs.GetDatesPicture() & ' ','') & | 
        CHOOSE(qField.Time = TRUE,' | ' & fs.GetTimesPicture() & ' ','') & | 
        ''')' & crlf
  .
  txt = txt & ' END' & crlf
  txt = txt & crlf
  txt = txt & LOC:Obj & ' FlatSerializer' & crlf
  txt = txt & crlf
  !Create code for deserializing
  txt = txt & ' CODE' & crlf
  txt = txt & crlf
  LOOP idxc = 1 TO RECORDS(qField)
    GET(qField,idxc)
    IF UPPER(qField.Name) = UPPER(qField.Label) THEN CYCLE.
    txt = txt & ' ' & LOC:Obj & '.AddFieldAliasByReference(' & CHOOSE(LOC:Pre<>'',LOC:Pre & ':',LOC:Label & '.') & qField.Label & ',''' & qField.Name & ''')' & crlf
  .
  txt = txt & ' ' & LOC:Obj & '.' & CHOOSE(isTsv<>0,'InitTSV','Init') & crlf
  txt = txt & ' !' & LOC:Obj & '.LoadString( string )' & crlf
  txt = txt & ' !' & LOC:Obj & '.LoadTextFile( filename )' & crlf
  txt = txt & ' ' & LOC:Obj & '.DeSerializeToQueue(' & LOC:Label & ')' & crlf
