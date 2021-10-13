  MEMBER()
  MAP
  END
  INCLUDE('Equates.CLW'),ONCE
  INCLUDE('FLATSERIALIZER.INC'),ONCE
!Carlos Gutierrez   carlosg@sca.mx    https://github.com/CarlosGtrz
!
!MIT License
!
!Copyright (c) 2021 Carlos Gutierrez Fragosa
!
!Permission is hereby granted, free of charge, to any person obtaining a copy
!of this software and associated documentation files (the "Software"), to deal
!in the Software without restriction, including without limitation the rights
!to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
!copies of the Software, and to permit persons to whom the Software is
!furnished to do so, subject to the following conditions:
!
!The above copyright notice and this permission notice shall be included in all
!copies or substantial portions of the Software.
!
!THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
!IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
!FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
!AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
!LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
!OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
!SOFTWARE.

FlatSerializer.Init PROCEDURE(<STRING pColumnSep>,<STRING pLineBreakString>,<STRING pQuoteSymbol>)
  CODE
  
  SELF.ColumnSep = ','
  SELF.LineBreakString = '<13,10>' 
  SELF.QuoteSymbol = '"'
  IF NOT OMITTED(pColumnSep)
    SELF.ColumnSep = CLIP(pColumnSep)
  .
  IF NOT OMITTED(pLineBreakString)
    SELF.LineBreakString = CLIP(pLineBreakString)
  .
  IF NOT OMITTED(pQuoteSymbol)
    SELF.QuoteSymbol = CLIP(pQuoteSymbol)
  .
  SELF.DatesPicture = '@D10-B'
  SELF.TimesPicture = '@T04B'
  SELF.IncludeHeaders = TRUE
  SELF.AlwaysQuoteStrings = TRUE
  SELF.RemovePrefixes = TRUE
  SELF.ReadLinesWithoutColumnSeparators = FALSE
  SELF.GroupTufoType = 0
  SELF.GroupTufoAddress = 0
  SELF.GroupTufoSize = 0
  SELF.Free(SELF.Fields)
  SELF.Free(SELF.ExcludedFields)
  SELF.Free(SELF.FieldsAlias)
  FREE(SELF.ColumnNames)
  SELF.FreeLineValues()
  
FlatSerializer.InitTSV  PROCEDURE
  CODE
  SELF.Init('<9>')
  SELF.SetAlwaysQuoteStrings(FALSE)
  
FlatSerializer.SetColumnSeparator   PROCEDURE(STRING pSep)
  CODE
  
  SELF.ColumnSep = pSep
  
FlatSerializer.SetLineBreakString   PROCEDURE(STRING pStr)
  CODE
  
  SELF.LineBreakString = pStr

FlatSerializer.SetQuoteSymbol   PROCEDURE(STRING pSym)
  CODE
  
  SELF.QuoteSymbol = pSym

FlatSerializer.SetDatesPicture  PROCEDURE(STRING pPic)
  CODE
  
  SELF.DatesPicture = pPic

FlatSerializer.SetTimesPicture  PROCEDURE(STRING pPic)
  CODE
  
  SELF.TimesPicture = pPic

FlatSerializer.SetIncludeHeaders    PROCEDURE(BOOL pVal)
  CODE
  
  SELF.IncludeHeaders = pVal  

FlatSerializer.SetAlwaysQuoteStrings    PROCEDURE(BOOL pVal)
  CODE
  
  SELF.AlwaysQuoteStrings = pVal  

FlatSerializer.SetRemovePrefixes   PROCEDURE(BOOL pVal)
  CODE
  
  SELF.RemovePrefixes = pVal  

FlatSerializer.SetReadLinesWithoutColumnSeparators  PROCEDURE(BOOL pVal)
  CODE
  
  SELF.ReadLinesWithoutColumnSeparators = pVal  

FlatSerializer.AddExcludedFieldByName   PROCEDURE(STRING pField)
  CODE
  
  CLEAR(SELF.ExcludedFields)
  SELF.ExcludedFields.Name = pField
  SELF.ExcludedFields.UpperName = UPPER(pField)
  ADD(SELF.ExcludedFields)

FlatSerializer.AddExcludedFieldByReference  PROCEDURE(*? pField)
  CODE
  
  CLEAR(SELF.ExcludedFields)
  SELF.ExcludedFields.Ref &= pField
  SELF.GetTufoInfo(pField,SELF.ExcludedFields.TufoType,SELF.ExcludedFields.TufoAddress,SELF.ExcludedFields.TufoSize)
  ADD(SELF.ExcludedFields)

FlatSerializer.SerializeGroupNames  PROCEDURE(*GROUP pGroup)!,STRING
names                                 ANY
idx                                   LONG
  CODE
  
  SELF.ParseGroup(pGroup)
  names = ''
  LOOP idx = 1 TO RECORDS(SELF.Fields)
    GET(SELF.Fields,idx)
    names = names & |
        CHOOSE(names <> '',SELF.ColumnSep,'') & |
        CLIP(SELF.Fields.Name)
  .
  RETURN names
  
FlatSerializer.SerializeGroupValues PROCEDURE(*GROUP pGroup)!,STRING
values                                ANY
idx                                   LONG
  CODE

  SELF.ParseGroup(pGroup)
  values = ''
  LOOP idx = 1 TO RECORDS(SELF.Fields)
    GET(SELF.Fields,idx)
    values = values & |
        CHOOSE(values <> '',SELF.ColumnSep,'') & |
        SELF.FormatFieldValue()    
  .
  RETURN values
  
FlatSerializer.SerializeGroup   PROCEDURE(*GROUP pGroup)!,STRING
idx                               LONG
serialized                        ANY
  CODE
  
  serialized = ''
  IF SELF.IncludeHeaders
    serialized = SELF.SerializeGroupNames(pGroup) & | 
        SELF.LineBreakString    
  .  
  serialized = serialized & |
      SELF.SerializeGroupValues(pGroup) & | 
      SELF.LineBreakString    
  RETURN serialized
  
FlatSerializer.SerializeQueue   PROCEDURE(*QUEUE pQueue)!,STRING
idx                               LONG
serialized                        ANY
  CODE
  
  serialized = ''
  IF SELF.IncludeHeaders
    serialized = SELF.SerializeGroupNames(pQueue) & | 
        SELF.LineBreakString    
  .  
  LOOP idx = 1 TO RECORDS(pQueue)
    GET(pQueue,idx)
    serialized = serialized & |
        SELF.SerializeGroupValues(pQueue) & | 
        SELF.LineBreakString    
  .
  RETURN serialized

FlatSerializer.SerializeFile    PROCEDURE(*FILE pFile,<*KEY pFileKey>)!,STRING
serialized                        ANY
filerec                              &GROUP
filekey                              &KEY
  CODE
  
  filerec &= pFile{PROP:Record}
  IF filerec &= NULL THEN RETURN ''.
  filekey &= NULL
  IF NOT OMITTED(pFileKey)    
    filekey &= pfileKey
  .
  IF filekey &= NULL AND pFile{PROP:Keys} > 0
    filekey &= pFile{PROP:Key,1}
  .  
  IF NOT filekey &= NULL
    SET(filekey)
  ELSE
    SET(pFile)
  .
  serialized = ''
  IF SELF.IncludeHeaders
    serialized = SELF.SerializeGroupNames(filerec) & | 
        SELF.LineBreakString    
  .  
  LOOP
    NEXT(pFile)
    IF ERRORCODE() THEN BREAK.
    serialized = serialized & |
        SELF.SerializeGroupValues(filerec) & | 
        SELF.LineBreakString
  .
  RETURN serialized  
  
FlatSerializer.SerializeGroupToTextFile PROCEDURE(*GROUP pGroup,STRING pFileName)
  CODE
  
  SELF.StringToTextFile(SELF.SerializeGroup(pGroup),pFileName)
  
FlatSerializer.SerializeQueueToTextFile    PROCEDURE(*QUEUE pQueue,STRING pFileName)
  CODE
  
  SELF.StringToTextFile(SELF.SerializeQueue(pQueue),pFileName)
  
FlatSerializer.SerializeFileToTextFile  PROCEDURE(*FILE pFile,STRING pFileName,<*KEY pFileKey>)
  CODE
  
  SELF.StringToTextFile(SELF.SerializeFile(pFile,pFileKey),pFileName)
  
FlatSerializer.AddFieldAliasByReference PROCEDURE(*? pField,STRING pAlias)
  CODE 
  
  CLEAR(SELF.FieldsAlias)
  SELF.FieldsAlias.Ref &= pField
  SELF.GetTufoInfo(pField,SELF.FieldsAlias.TufoType,SELF.FieldsAlias.TufoAddress,SELF.FieldsAlias.TufoSize)
  SELF.FieldsAlias.Name = pAlias
  SELF.FieldsAlias.UpperName = UPPER(pAlias)
  ADD(SELF.FieldsAlias)

FlatSerializer.LoadString   PROCEDURE(STRING pText)
pos                           LONG
inHeaders                     LONG
inQuote                       LONG
valueStart                    LONG
valueEnd                      LONG
unescapedVal                  ANY
lineHasValues                 LONG
lineEnd                       LONG
pTextLen                      LONG
QuoteSymbolLen                LONG
ColumnSepLen                  LONG
LineBreakLen                  LONG

  CODE    
  
  FREE(SELF.ColumnNames)
  SELF.FreeLineValues
  CLEAR(SELF.LineValues)
  inHeaders = 1
  inQuote = 0
  valueStart = 1
  valueEnd = 0
  lineEnd = 0
  lineHasValues = 0
  pTextLen = LEN(pText)
  QuoteSymbolLen = LEN(SELF.QuoteSymbol)
  ColumnSepLen = LEN(SELF.ColumnSep)
  LineBreakLen = LEN(SELF.LineBreakString)
  pos = 0
  LOOP
    pos += 1
    IF pos > pTextLen THEN BREAK.    
    
    !Detect quote
    IF pos >= QuoteSymbolLen  AND pText[ pos - QuoteSymbolLen + 1 : pos ] = SELF.QuoteSymbol
      inQuote = CHOOSE(NOT inQuote)
    .
    
    IF NOT inQuote
      !Detect end of column 
      IF pos >= ColumnSepLen AND pText[ pos - ColumnSepLen + 1 : pos ] = SELF.ColumnSep
        valueEnd = pos - ColumnSepLen
        lineHasValues = 1
      .
      !Detect end of line
      IF pos >= LineBreakLen AND pText[ pos - LineBreakLen + 1 : pos ] = SELF.LineBreakString 
        IF NOT lineHasValues AND NOT SELF.ReadLinesWithoutColumnSeparators
          !Skip empty line
          valueStart = pos+1
          CYCLE
        .        
        valueEnd = pos - LineBreakLen
        lineEnd = pos 
      .      
      !Detect end of text
      IF pos = pTextLen   
        IF NOT valueEnd
          valueEnd = pos
        .        
        lineEnd = pos 
      .
      IF valueEnd
        !Remove Excel formula string constant start
        IF valueEnd - valueStart + 1 >= QuoteSymbolLen+1
          IF pText[ valueStart : valueStart + QuoteSymbolLen+1 - 1 ] = '='&SELF.QuoteSymbol
            valueStart += QuoteSymbolLen+1
          .
        .
        !Remove starting quotes
        IF valueEnd - valueStart + 1 >= QuoteSymbolLen
          IF pText[ valueStart : valueStart + QuoteSymbolLen - 1 ] = SELF.QuoteSymbol
            valueStart += QuoteSymbolLen
          .
        .
        !Remove ending quotes
        IF valueEnd - valueStart + 1 >= QuoteSymbolLen
          IF pText[ valueEnd - QuoteSymbolLen + 1 : valueEnd ] = SELF.QuoteSymbol
            valueEnd -= QuoteSymbolLen
          .
        .
        unescapedVal = SELF.UnEscapeQuotes(pText[valueStart : valueEnd])     
        IF inHeaders
          CLEAR(SELF.ColumnNames)
          SELF.ColumnNames.Name = unescapedVal
          SELF.ColumnNames.UpperName = UPPER(unescapedVal)
          ADD(SELF.ColumnNames)
        ELSE
          IF SELF.LineValues.ColumnValues &= NULL
            SELF.LineValues.ColumnValues &= NEW fsColumnValues
          .
          SELF.LineValues.ColumnValues.Value &= NEW STRING(LEN(unescapedVal))
          SELF.LineValues.ColumnValues.Value = unescapedVal
          ADD(SELF.LineValues.ColumnValues)
        .        
        valueStart = pos + 1
        valueEnd = 0        
      .
      IF lineEnd 
        IF inHeaders
          inHeaders = 0
        ELSE
          ADD(SELF.LineValues)
          CLEAR(SELF.LineValues)
        .
        lineEnd = 0
        lineHasValues = 0
      .      
    .
  .  
  
FlatSerializer.LoadTextFile PROCEDURE(STRING pFileName)
  CODE
  
  SELF.LoadString(SELF.StringFromTextFile(pFileName))      
   
FlatSerializer.GetLinesCount    PROCEDURE()!,LONG
  CODE
  
  RETURN RECORDS(SELF.LineValues)
  
FlatSerializer.GetValueByName   PROCEDURE(STRING pColumnName,LONG pLine = 1)!,STRING  
  CODE

  CLEAR(SELF.ColumnNames)
  SELF.ColumnNames.UpperName = UPPER(pColumnName)
  GET(SELF.ColumnNames,SELF.ColumnNames.UpperName)
  IF ERRORCODE() THEN RETURN ''.

  CLEAR(SELF.LineValues)
  GET(SELF.LineValues,pLine)
  IF ERRORCODE() THEN RETURN ''.
  
  CLEAR(SELF.LineValues.ColumnValues)
  GET(SELF.LineValues.ColumnValues,POINTER(SELF.ColumnNames))
  IF ERRORCODE() THEN RETURN ''.
  
  RETURN SELF.DeformatColumnValue() 
  
FlatSerializer.DeSerializeToGroup   PROCEDURE(*GROUP pGroup,LONG pLine = 1)
idx                                   LONG
  CODE
  
  SELF.ParseGroup(pGroup)
  CLEAR(SELF.LineValues)
  GET(SELF.LineValues,pLine)
  IF ERRORCODE() THEN RETURN.
  LOOP idx = 1 TO RECORDS(SELF.ColumnNames)
    GET(SELF.ColumnNames,idx)
    CLEAR(SELF.LineValues.ColumnValues)
    GET(SELF.LineValues.ColumnValues,idx)
    CLEAR(SELF.FieldsAlias)
    CLEAR(SELF.Fields)
    SELF.Fields.UpperName = SELF.ColumnNames.UpperName
    GET(SELF.Fields,SELF.Fields.UpperName)
    IF ERRORCODE() THEN 
      !Look for alias
      IF NOT RECORDS(SELF.FieldsAlias) THEN CYCLE.
      CLEAR(SELF.FieldsAlias)
      SELF.FieldsAlias.UpperName = SELF.ColumnNames.UpperName
      GET(SELF.FieldsAlias,SELF.FieldsAlias.UpperName)
      IF ERRORCODE() THEN CYCLE.      
      !Alias found, get field
      CLEAR(SELF.Fields)
      SELF.Fields.TufoType = SELF.FieldsAlias.TufoType
      SELF.Fields.TufoAddress = SELF.FieldsAlias.TufoAddress
      SELF.Fields.TufoSize = SELF.FieldsAlias.TufoSize
      GET(SELF.Fields,SELF.Fields.TufoType,SELF.Fields.TufoAddress,SELF.Fields.TufoSize)
      IF ERRORCODE() THEN CYCLE.
    .
    SELF.Fields.Ref = SELF.DeformatColumnValue()
  .
  
FlatSerializer.DeSerializeToQueue   PROCEDURE(*QUEUE pQueue)
idx                                   LONG
  CODE
  
  LOOP idx = 1 TO SELF.GetLinesCount()
    CLEAR(pQueue)
    SELF.DeSerializeToGroup(pQueue,idx)
    ADD(pQueue)
  .

FlatSerializer.DeSerializeToFile    PROCEDURE(*FILE pFile)
idx                                   LONG
fgr                                   &GROUP
  CODE
  
  fgr &= pFile{PROP:Record}
  IF fgr &= NULL THEN RETURN.
  LOOP idx = 1 TO SELF.GetLinesCount()
    CLEAR(fgr)
    SELF.DeSerializeToGroup(fgr,idx)
    ADD(pFile)
  .
  
FlatSerializer.ParseGroup   PROCEDURE(*GROUP pGroup,LONG pLevel = 1)!,PRIVATE
idx                           LONG
nam                           ANY
ref                           ANY
pos                           LONG
grref                         &GROUP
gTufoType                     LONG
gTufoAddress                  LONG
gTufoSize                     LONG
  CODE
  
  IF pLevel = 1    
    SELF.GetTufoInfo(pGroup,gTufoType,gTufoAddress,gTufoType)
    IF SELF.GroupTufoType = gTufoType AND SELF.GroupTufoAddress = gTufoAddress AND SELF.GroupTufoSize = gTufoSize THEN RETURN. !Don't parse again same group
    SELF.GroupTufoType = gTufoType
    SELF.GroupTufoAddress = gTufoAddress
    SELF.GroupTufoSize = gTufoSize
    SELF.Free(SELF.Fields)
  .
  idx = 0
  LOOP
    idx += 1
    CLEAR(SELF.Fields)
    SELF.Fields.Ref &= WHAT(pGroup,idx)
    IF SELF.Fields.Ref &= NULL THEN BREAK.
    SELF.GetTufoInfo(SELF.Fields.Ref,SELF.Fields.TufoType,SELF.Fields.TufoAddress,SELF.Fields.TufoSize)
    nam = WHO(pGroup,idx)
    !Remove extended name attributes
    pos = INSTRING('|',nam,1,1)
    IF pos
      nam = SUB(nam,1,pos-1)
    .    
    IF SELF.RemovePrefixes
      pos = INSTRING(':',nam,1,1)      
      IF pos
        nam = SUB(nam,pos+1,LEN(nam)-pos)        
      .    
    .    
    IF NOT nam 
      nam = 'Field'&idx
    .    
    SELF.Fields.Name = nam
    SELF.Fields.UpperName = UPPER(nam)    
    IF SELF.IsExcluded()
      SELF.Fields.Ref &= NULL
      CYCLE
    .
    SELF.Fields.Level = pLevel
    SELF.Fields.IsGroup = ISGROUP(pGroup,idx)
    ADD(SELF.Fields)
    IF ISGROUP(pGroup,idx)
      grref &= GETGROUP(pGroup,idx)
      idx += SELF.FieldsInGroup(grref)
      SELF.ParseGroup(grref,pLevel+1)
    .
  .
  
FlatSerializer.IsExcluded   PROCEDURE()!,BOOL,PRIVATE
idx                           LONG
  CODE
  
  CLEAR(SELF.ExcludedFields)
  SELF.ExcludedFields.UpperName = SELF.Fields.UpperName
  GET(SELF.ExcludedFields,SELF.ExcludedFields.UpperName)
  IF NOT ERRORCODE() THEN RETURN TRUE.

  CLEAR(SELF.ExcludedFields)
  SELF.ExcludedFields.TufoType = SELF.Fields.TufoType
  SELF.ExcludedFields.TufoAddress = SELF.Fields.TufoAddress
  SELF.ExcludedFields.TufoSize = SELF.Fields.TufoSize
  GET(SELF.ExcludedFields,SELF.ExcludedFields.TufoType,SELF.ExcludedFields.TufoAddress,SELF.ExcludedFields.TufoSize)
  IF NOT ERRORCODE() THEN RETURN TRUE.

  RETURN FALSE
  
FlatSerializer.FieldsInGroup    PROCEDURE(*GROUP pGroup)!,LONG,PRIVATE
idx                               LONG
fld                               ANY
grpref                            &GROUP
count                             LONG
  CODE
  
  LOOP
    idx += 1
    fld &= WHAT(pGroup,idx)
    IF fld &= NULL THEN BREAK.
    IF ISGROUP(pGroup,idx)
      grpref &= GETGROUP(pGroup,idx)
      count += SELF.FieldsInGroup(grpref)
    ELSE
      count += 1
    .
  .
  RETURN count
  
FlatSerializer.FormatFieldValue  PROCEDURE()!,STRING,PRIVATE
value                         ANY
  CODE
  
  IF LEFT(SELF.Fields.Ref,2) = '="' AND RIGHT(SELF.Fields.Ref,1) = '"' !Excel won't quote separators inside formula string constant
    RETURN '="'&SELF.BlankSeparators(SUB(SELF.Fields.Ref,3,LEN(SELF.Fields.Ref)-3))&'"' !Replace separators with ' '
  .  
  value = ''    
  CASE SELF.Fields.TufoType
    OF DataType:BYTE 
    OROF DataType:SHORT 
    OROF DataType:USHORT 
    OROF DataType:LONG       
    OROF DataType:ULONG 
    OROF DataType:DECIMAL 
    OROF DataType:PDECIMAL 
    OROF DataType:REAL 
    OROF DataType:SREAL
      !Numbers
      value = SELF.Fields.Ref
    OF DataType:DATE
      value = FORMAT(SELF.Fields.Ref,SELF.DatesPicture)
    OF DataType:TIME
      value = FORMAT(SELF.Fields.Ref,SELF.TimesPicture)
    ELSE
      !Strings
      IF SELF.AlwaysQuoteStrings OR |
          INSTRING(SELF.ColumnSep,SELF.Fields.Ref,1,1) OR |
          INSTRING(SELF.LineBreakString,SELF.Fields.Ref,1,1) OR |
          INSTRING(SELF.QuoteSymbol,SELF.Fields.Ref,1,1) 
        value = SELF.QuoteSymbol & SELF.EscapeQuotes(CLIP(SELF.Fields.Ref)) & SELF.QuoteSymbol
      ELSE
        value = CLIP(SELF.Fields.Ref)
      .      
  .
  RETURN value

FlatSerializer.DeformatColumnValue  PROCEDURE()!,STRING,PRIVATE
value                             ANY
  CODE  

  value = ''
  CASE SELF.Fields.TufoType
    OF DataType:DATE
      value = DEFORMAT(SELF.LineValues.ColumnValues.Value,SELF.DatesPicture)
    OF DataType:TIME
      value = DEFORMAT(SELF.LineValues.ColumnValues.Value,SELF.TimesPicture)
    ELSE
      value = SELF.LineValues.ColumnValues.Value
  .
  RETURN value
  
FlatSerializer.EscapeQuotes PROCEDURE(STRING pText)!,STRING,PRIVATE
  CODE    

  RETURN SELF.Replace(pText,SELF.QuoteSymbol,SELF.QuoteSymbol&SELF.QuoteSymbol)
  
FlatSerializer.UnEscapeQuotes   PROCEDURE(STRING pText)!,STRING,PRIVATE
  CODE  
  
  RETURN SELF.Replace(pText,SELF.QuoteSymbol&SELF.QuoteSymbol,SELF.QuoteSymbol)
  
FlatSerializer.BlankSeparators  PROCEDURE(STRING pText)!,STRING,PRIVATE  
value                             ANY
  CODE
  
  value = pText
  value = SELF.Replace(value,SELF.ColumnSep,' ')
  value = SELF.Replace(value,SELF.LineBreakString,' ')
  value = SELF.Replace(value,SELF.QuoteSymbol,' ')
  RETURN CLIP(value)
  
FlatSerializer.Replace  PROCEDURE(STRING pText,STRING pOldString,STRING pNewString)!,STRING,PRIVATE
value                     ANY
start                     LONG
pos                       LONG
  CODE    
  value = pText  
  start = 1
  LOOP
    pos = INSTRING(pOldString,value,1,start)
    IF NOT pos THEN BREAK.
    value = SUB(value,1,pos-1)& |
        pNewString& |
        SUB(value,pos+LEN(pOldString),LEN(value) - pos - LEN(pOldString) + 1)
    start = pos+LEN(pNewString)
  .
  RETURN value  
  
FlatSerializer.GetTufoInfo  PROCEDURE(*? pAny,*LONG pType,*LONG pAddress,*LONG pSize)
!REGION TUFO
!From https://github.com/MarkGoldberg/ClarionCommunity/blob/master/CW/Shared/Src/TUFO.INT
                              OMIT('***',_C70_)
!--- see softvelocity.public.clarion6 "Variable Data Type" Sept,12,2006 (code posted by dedpahom) -----!
tmTUFO                        INTERFACE,TYPE
AssignLong                      PROCEDURE                           !+00h 
AssignReal                      PROCEDURE                           !+04h 
AssignUFO                       PROCEDURE                           !+08h 
DistinctsUFO                    PROCEDURE                           !+0Ch
DistinctsLong                   PROCEDURE                           !+10h
_Type                           PROCEDURE(LONG _UfoAddr),LONG       !+14h 
ToMem                           PROCEDURE                           !+18h
FromMem                         PROCEDURE                           !+1Ch
OldFromMem                      PROCEDURE                           !+20h
Pop                             PROCEDURE(LONG _UfoAddr)            !+24h
Push                            PROCEDURE(LONG _UfoAddr)            !+28h
DPop                            PROCEDURE(LONG _UfoAddr)            !+2Ch 
DPush                           PROCEDURE(LONG _UfoAddr)            !+30h 
_Real                           PROCEDURE(LONG _UfoAddr),REAL       !+34h 
_Long                           PROCEDURE(LONG _UfoAddr),LONG       !+38h
_Free                           PROCEDURE(LONG _UfoAddr)            !+3Ch
_Clear                          PROCEDURE                           !+40h
_Address                        PROCEDURE(LONG _UfoAddr),LONG       !+44h
AClone                          PROCEDURE(LONG _UfoAddr),LONG       !+48h
Select                          PROCEDURE                           !+4Ch 
Slice                           PROCEDURE                           !+50h 
Designate                       PROCEDURE                           !+54h
_Max                            PROCEDURE(LONG _UfoAddr),LONG       !+58h
_Size                           PROCEDURE(LONG _UfoAddr),LONG       !+5Ch
BaseType                        PROCEDURE(LONG _UfoAddr),LONG       !+60h
DistinctUpper                   PROCEDURE                           !+64h
Cleared                         PROCEDURE(LONG _UfoAddr)            !+68h
IsNull                          PROCEDURE(LONG _UfoAddr),LONG       !+6Ch
OEM2ANSI                        PROCEDURE(LONG _UfoAddr)            !+70h
ANSI2OEM                        PROCEDURE(LONG _UfoAddr)            !+74h
_Bind                           PROCEDURE(LONG _UfoAddr)            !+78h
_Add                            PROCEDURE                           !+7Ch
Divide                          PROCEDURE                           !+80h
Hash                            PROCEDURE(LONG _UfoAddr),LONG       !+84h
SetAddress                      PROCEDURE                           !+88h 
Match                           PROCEDURE                           !+8Ch 
Identical                       PROCEDURE                           !+90h
Store                           PROCEDURE                           !+94h
                              END
                              !END-OMIT('***',_C70_)
                              COMPILE('***',_C70_)
!According to Randy Rogers (Skype PM, Dec 13, 2010)
tmTUFO                        INTERFACE,TYPE
_Type                           PROCEDURE(LONG _UfoAddr),LONG       !+00h
ToMem                           PROCEDURE                           !+04h
FromMem                         PROCEDURE                           !+08h
OldFromMem                      PROCEDURE                           !+0Ch
Pop                             PROCEDURE(LONG _UfoAddr)            !+10h get a value from string stack
Push                            PROCEDURE(LONG _UfoAddr)            !+14h put a vaule to string stack
DPop                            PROCEDURE(LONG _UfoAddr)            !+18h get a value from DECIMAL stack
DPush                           PROCEDURE(LONG _UfoAddr)            !+1Ch put a vaule to DECIMAL stack
_Real                           PROCEDURE(LONG _UfoAddr),REAL       !+20h get a value as REAL
_Long                           PROCEDURE(LONG _UfoAddr),LONG       !+24h get a value as LONG
_Free                           PROCEDURE(LONG _UfoAddr)            !+28h disposes memory and frees a reference (sets it to NULL)
_Clear                          PROCEDURE                           !+2Ch clears a variable
_Address                        PROCEDURE(LONG _UfoAddr),LONG       !+30h returns an address of a variable
AssignLong                      PROCEDURE                           !+34h
AssignReal                      PROCEDURE                           !+38h
AssignUFO                       PROCEDURE                           !+3Ch
AClone                          PROCEDURE(LONG _UfoAddr),LONG       !+40h
Select                          PROCEDURE                           !+44h
Slice                           PROCEDURE                           !+48h
Designate                       PROCEDURE                           !+4Ch returns group field as UFO object
_Max                            PROCEDURE(LONG _UfoAddr),LONG       !+50h number of elements in first dimension of an array
_Size                           PROCEDURE(LONG _UfoAddr),LONG       !+54h size of an object
BaseType                        PROCEDURE(LONG _UfoAddr),LONG       !+58h
DistinctUpper                   PROCEDURE                           !+5Ch
DistinctsUFO                    PROCEDURE                           !+60h
DistinctsLong                   PROCEDURE                           !+64h
Cleared                         PROCEDURE(LONG _UfoAddr)            !+68h was an object disposed?
IsNull                          PROCEDURE(LONG _UfoAddr),LONG       !+6Ch
OEM2ANSI                        PROCEDURE(LONG _UfoAddr)            !+70h
ANSI2OEM                        PROCEDURE(LONG _UfoAddr)            !+74h
_Bind                           PROCEDURE(LONG _UfoAddr)            !+78h bind all fields of a group
_Add                            PROCEDURE                           !+7Ch
Divide                          PROCEDURE                           !+80h
Hash                            PROCEDURE(LONG _UfoAddr),LONG       !+84h Calc CRC
SetAddress                      PROCEDURE                           !+88h sets the address of a variable
Match                           PROCEDURE                           !+8Ch compares the type and the size of a field with a field of ClassDesc structure
Identical                       PROCEDURE                           !+90h
Store                           PROCEDURE                           !+94h writes the value of an object into the memory address
                              END
                              !END-COMPILE('***',_C70_)
!ENDREGION
tufo                          &tmTUFO
addr                          LONG
  CODE
  
  addr = ADDRESS(pAny)
  IF NOT addr THEN RETURN.
  tufo &= addr+0
  pType = tufo._Type(addr)
  pAddress = tufo._Address(addr)
  pSize = tufo._Size(addr)
  
FlatSerializer.Free PROCEDURE(fsFieldsQueue pQueue)!,PRIVATE
idx                   LONG
  CODE
  
  IF pQueue &= NULL THEN RETURN. 
  LOOP idx = RECORDS(pQueue) TO 1 BY -1
    GET(pQueue,idx)
    pQueue.Ref &= NULL
    DELETE(pQueue)
  .
    
FlatSerializer.FreeLineValues   PROCEDURE!,PRIVATE
idx                               LONG
idx2                              LONG
  CODE
  
  IF SELF.LineValues &= NULL THEN RETURN.
  LOOP idx = RECORDS(SELF.LineValues) TO 1 BY -1
    GET(SELF.LineValues,idx)
    IF NOT SELF.LineValues.ColumnValues &= NULL
      LOOP idx2 = RECORDS(SELF.LineValues.ColumnValues) TO 1 BY -1
        GET(SELF.LineValues.ColumnValues,idx2)
        DISPOSE(SELF.LineValues.ColumnValues.Value)
        DELETE(SELF.LineValues.ColumnValues)
      .
      DISPOSE(SELF.LineValues.ColumnValues)
    .
    DELETE(SELF.LineValues)
  .
  
FlatSerializer.StringToTextFile PROCEDURE(STRING pStr,STRING pFileName)!,PRIVATE
bufSize                               EQUATE(32768)
dosFile                               FILE,DRIVER('DOS'),CREATE
buf                                     RECORD;STRING(bufSize).
                                      END
pos                                   LONG(1)
  CODE  
  dosFile{PROP:Name} = pFileName
  CREATE(dosFile)
  IF ERRORCODE() THEN RETURN.
  OPEN(dosFile)
  IF ERRORCODE() THEN RETURN.
  LOOP UNTIL pos > LEN(pStr)
    dosFile.Buf = pStr[ pos : LEN(pStr) ]
    ADD(dosFile, |
        CHOOSE(pos + bufSize > LEN(pStr), |
        LEN(pStr) - pos + 1, |
        bufSize))
    pos += bufSize
  .
  CLOSE(dosfile)
  
FlatSerializer.StringFromTextFile   PROCEDURE(STRING pFileName)!,STRING,PRIVATE
bufSize                                   EQUATE(32768)
dosFile                                   FILE,DRIVER('DOS'),CREATE
buf                                         RECORD;STRING(bufSize).
                                          END
pos                                       LONG(1)
fileSize                                  LONG
str                                       ANY
  CODE  
  dosFile{PROP:Name} = pFileName   
  OPEN(dosFile)
  IF ERRORCODE() THEN RETURN ''.  
  fileSize = BYTES(dosFile)  
  IF NOT fileSize THEN 
    CLOSE(dosFile)
    RETURN ''
  .
  str = ''
  LOOP UNTIL pos > fileSize
    GET(dosFile,pos)
    str = str & SUB(dosFile.buf,1,| 
        CHOOSE(pos + bufSize > fileSize, |
        fileSize - pos + 1, |
        bufSize))    
    pos += bufSize    
  .
  CLOSE(dosfile)
  RETURN str

FlatSerializer.DebugView    PROCEDURE(STRING pStr)
pre                           STRING('fs')
lcstr                         CSTRING(SIZE(pre)+SIZE(pStr)+3)
  CODE
  lcstr = pre&'|'&pStr&'|'
  fs_OutputDebugString(lcstr)  
  
FlatSerializer.Construct    PROCEDURE
  CODE
  
  SELF.ExcludedFields &= NEW fsFieldsQueue
  SELF.Fields &= NEW fsFieldsQueue
  SELF.FieldsAlias &= NEW fsFieldsQueue
  SELF.ColumnNames &= NEW fsColumnNames
  SELF.LineValues &= NEW fsLineValues
  SELF.Init
  
FlatSerializer.Destruct PROCEDURE
  CODE
  
  SELF.Free(SELF.Fields)
  DISPOSE(SELF.Fields)  
  SELF.Free(SELF.ExcludedFields)
  DISPOSE(SELF.ExcludedFields)
  SELF.Free(SELF.FieldsAlias)
  DISPOSE(SELF.FieldsAlias)
  DISPOSE(SELF.ColumnNames)
  SELF.FreeLineValues
  DISPOSE(SELF.LineValues) 
  
