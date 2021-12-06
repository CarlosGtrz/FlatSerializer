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

  MAP
    MODULE('win32')
      fs_OutputDebugString(*CSTRING cstr),PASCAL,RAW,NAME('OutputDebugStringA')      
    END
  END

fsColumnNames       QUEUE,TYPE
Name                  STRING(60)
UpperName             STRING(60)
FieldUpperName        STRING(60)
                    END

fsColumnValues      QUEUE,TYPE
Value                 &STRING
                    END

fsLineValues        QUEUE,TYPE
ColumnValues          &fsColumnValues
                    END


!Local Class, inspired by StringClass in libsrc/xmlclass.inc & TreeViewWrap.clw
fsDynString         CLASS,TYPE
s                     &STRING,PRIVATE
len                   LONG,PRIVATE
set                   PROCEDURE(STRING str)
get                   PROCEDURE(),STRING
get                   PROCEDURE(LONG pstart,LONG pend),STRING
len                   PROCEDURE(),LONG
append                PROCEDURE(STRING str)
append                PROCEDURE(STRING str,STRING sep)
replace               PROCEDURE(STRING pOldString,STRING pNewString)
Destruct              PROCEDURE
                    END

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
  SELF.SerializeUsingAlias = FALSE 
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

FlatSerializer.GetDatesPicture  PROCEDURE
  CODE
  
  RETURN SELF.DatesPicture

FlatSerializer.SetTimesPicture  PROCEDURE(STRING pPic)
  CODE
  
  SELF.TimesPicture = pPic

FlatSerializer.GetTimesPicture  PROCEDURE
  CODE
  
  RETURN SELF.TimesPicture

FlatSerializer.SetIncludeHeaders    PROCEDURE(BOOL pVal)
  CODE
  
  SELF.IncludeHeaders = pVal  

FlatSerializer.SetAlwaysQuoteStrings    PROCEDURE(BOOL pVal)
  CODE
  
  SELF.AlwaysQuoteStrings = pVal  

FlatSerializer.SetRemovePrefixes   PROCEDURE(BOOL pVal)
  CODE
  
  SELF.RemovePrefixes = pVal  

FlatSerializer.SetSerializeUsingAlias   PROCEDURE(BOOL pVal)
  CODE
  
  SELF.SerializeUsingAlias = pVal  

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
names                                 fsDynString
nam                                   LIKE(SELF.Fields.Name)
idx                                   LONG
  CODE
  
  SELF.ParseGroup(pGroup)
  LOOP idx = 1 TO RECORDS(SELF.Fields)
    GET(SELF.Fields,idx)
    IF SELF.SerializeUsingAlias
      nam = SELF.FindSerializeAlias()
    ELSE
      nam = SELF.Fields.Name
    .    
    names.append(CLIP(nam),SELF.ColumnSep)
  .
  RETURN names.get()

FlatSerializer.SerializeGroupValues PROCEDURE(*GROUP pGroup)!,STRING
values                                fsDynString
idx                                   LONG
  CODE

  SELF.ParseGroup(pGroup)
  LOOP idx = 1 TO RECORDS(SELF.Fields)
    GET(SELF.Fields,idx)
    values.append(SELF.FormatFieldValue(),SELF.ColumnSep)
  .
  RETURN values.get()
  
FlatSerializer.SerializeGroup   PROCEDURE(*GROUP pGroup)!,STRING
idx                               LONG
serialized                        fsDynString
  CODE
  
  IF SELF.IncludeHeaders
    serialized.set( SELF.SerializeGroupNames(pGroup) & SELF.LineBreakString )
  .  
  serialized.append( SELF.SerializeGroupValues(pGroup) & SELF.LineBreakString )  
  RETURN serialized.get()
  
FlatSerializer.SerializeQueue   PROCEDURE(*QUEUE pQueue)!,STRING
idx                               LONG
serialized                        fsDynString
  CODE
  
  IF SELF.IncludeHeaders
    serialized.set( SELF.SerializeGroupNames(pQueue) & SELF.LineBreakString )
    
  .  
  LOOP idx = 1 TO RECORDS(pQueue)
    GET(pQueue,idx)
    serialized.append( SELF.SerializeGroupValues(pQueue) & SELF.LineBreakString )    
  .
  RETURN serialized.get()

FlatSerializer.SerializeFile    PROCEDURE(*FILE pFile,<*KEY pFileKey>)!,STRING
serialized                        fsDynString
filerec                           &GROUP
filekey                           &KEY
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
  IF SELF.IncludeHeaders
    serialized.set( SELF.SerializeGroupNames(filerec) & SELF.LineBreakString )    
  .  
  LOOP
    NEXT(pFile)
    IF ERRORCODE() THEN BREAK.
    serialized.append( SELF.SerializeGroupValues(filerec) & SELF.LineBreakString )    
  .
  RETURN serialized.get()
  
FlatSerializer.SerializeGroupToTextFile PROCEDURE(*GROUP pGroup,STRING pFileName)
  CODE
  
  SELF.StringToTextFile(SELF.SerializeGroup(pGroup),pFileName)
  
FlatSerializer.SerializeQueueToTextFile    PROCEDURE(*QUEUE pQueue,STRING pFileName)
  CODE
  
  SELF.StringToTextFile(SELF.SerializeQueue(pQueue),pFileName)
  
FlatSerializer.SerializeFileToTextFile  PROCEDURE(*FILE pFile,STRING pFileName,<*KEY pFileKey>)
  CODE
  
  SELF.StringToTextFile(SELF.SerializeFile(pFile,pFileKey),pFileName)
  
FlatSerializer.LoadString   PROCEDURE(STRING pText)
pos                           LONG
inHeaders                     LONG
inQuote                       LONG
valueStart                    LONG
valueEnd                      LONG
unescapedVal                  fsDynString
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
  pTextLen = SIZE(pText)
  QuoteSymbolLen = LEN(SELF.QuoteSymbol)
  ColumnSepLen = LEN(SELF.ColumnSep)
  LineBreakLen = LEN(SELF.LineBreakString)
  pos = 0
  LOOP
    pos += 1
    IF pos > pTextLen THEN BREAK.    
    
    !Detect quote
    IF pos >= QuoteSymbolLen  AND pText[ pos - QuoteSymbolLen + 1 : pos ] = SELF.QuoteSymbol
      inQuote = 1 - inQuote!CHOOSE(NOT inQuote)
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
        unescapedVal.set(SELF.UnEscapeQuotes(pText[valueStart : valueEnd]))
        IF inHeaders
          CLEAR(SELF.ColumnNames)
          SELF.ColumnNames.Name = unescapedVal.get()
          SELF.ColumnNames.UpperName = UPPER(SELF.ColumnNames.Name)
          ADD(SELF.ColumnNames)
        ELSE
          IF SELF.LineValues.ColumnValues &= NULL
            SELF.LineValues.ColumnValues &= NEW fsColumnValues
          .
          SELF.LineValues.ColumnValues.Value &= NEW STRING (unescapedVal.len())
          SELF.LineValues.ColumnValues.Value = unescapedVal.get()
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
str &STRING
  CODE
  
  str &= SELF.StringFromTextFile(pFileName)
  IF str &= NULL THEN RETURN.
  SELF.LoadString(str)
  DISPOSE(str)
   
FlatSerializer.GetLinesCount    PROCEDURE()!,LONG
  CODE
  
  RETURN RECORDS(SELF.LineValues)

FlatSerializer.GetColumnsCount PROCEDURE()!,LONG
  CODE
  
  RETURN RECORDS(SELF.ColumnNames)

FlatSerializer.GetColumnName    PROCEDURE(LONG pColumnNumber)!,STRING
  CODE
  
  CLEAR(SELF.ColumnNames)
  GET(SELF.ColumnNames,pColumnNumber)
  RETURN CLIP(SELF.ColumnNames.Name)

FlatSerializer.GetValueByName   PROCEDURE(STRING pColumnName,LONG pLineNumber = 1,LONG pDeformatOptions = 1)!,STRING
  CODE

  CLEAR(SELF.ColumnNames)
  SELF.ColumnNames.UpperName = UPPER(pColumnName)
  GET(SELF.ColumnNames,SELF.ColumnNames.UpperName)
  IF ERRORCODE() THEN RETURN ''.
  CLEAR(SELF.LineValues)
  GET(SELF.LineValues,pLineNumber)
  IF ERRORCODE() THEN RETURN ''.
  CLEAR(SELF.LineValues.ColumnValues)
  GET(SELF.LineValues.ColumnValues,POINTER(SELF.ColumnNames))
  IF ERRORCODE() THEN RETURN ''.
  RETURN SELF.DeformatColumnValue(pDeformatOptions)
  
FlatSerializer.DeSerializeToGroup   PROCEDURE(*GROUP pGroup,LONG pLineNumber = 1)
idx                                   LONG
  CODE
  
  SELF.ParseGroup(pGroup)
  CLEAR(SELF.LineValues)
  GET(SELF.LineValues,pLineNumber)
  IF ERRORCODE() THEN RETURN.
  LOOP idx = 1 TO RECORDS(SELF.ColumnNames)
    GET(SELF.ColumnNames,idx)
    CLEAR(SELF.LineValues.ColumnValues)
    GET(SELF.LineValues.ColumnValues,idx)
    CLEAR(SELF.Fields)
    SELF.Fields.UpperName = SELF.ColumnNames.FieldUpperName
    GET(SELF.Fields,SELF.Fields.UpperName)
    IF ERRORCODE() THEN CYCLE.
    SELF.Fields.Ref = SELF.DeformatColumnValueForField()
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
  
FlatSerializer.AddFieldAliasByReference PROCEDURE(*? pField,STRING pAlias)
  CODE 
  
  CLEAR(SELF.FieldsAlias)
  SELF.FieldsAlias.Ref &= pField
  SELF.GetTufoInfo(pField,SELF.FieldsAlias.TufoType,SELF.FieldsAlias.TufoAddress,SELF.FieldsAlias.TufoSize)
  SELF.FieldsAlias.Name = pAlias
  SELF.FieldsAlias.UpperName = UPPER(pAlias)
  ADD(SELF.FieldsAlias)  
  
FlatSerializer.DebugView    PROCEDURE(STRING pStr)
pre                           STRING('fs')
lcstr                         CSTRING(SIZE(pre)+SIZE(pStr)+3)
  CODE
  
  lcstr = pre&'|'&pStr&'|'
  fs_OutputDebugString(lcstr)  

FlatSerializer.StringToTextFile PROCEDURE(STRING pStr,STRING pFileName)!
bufSize                           EQUATE(32768)
dosFile                           FILE,DRIVER('DOS'),CREATE
buf                                 RECORD;STRING(bufSize).
                                  END
pos                               LONG(1)
strLen                            LONG
  CODE  
  
  dosFile{PROP:Name} = pFileName
  CREATE(dosFile)
  IF ERRORCODE() THEN RETURN.
  OPEN(dosFile,12h) !ReadWrite+DenyAll
  IF ERRORCODE() THEN RETURN.
  strLen = LEN(pStr)
  LOOP UNTIL pos > strLen
    dosFile.Buf = pStr[ pos : strLen ]
    ADD(dosFile, |
        CHOOSE(pos + bufSize > strLen, |
        strLen - pos + 1, |
        bufSize))
    pos += bufSize
  .
  CLOSE(dosfile)
  
FlatSerializer.StringFromTextFile   PROCEDURE(STRING pFileName)!,*STRING
bufSize                               EQUATE(32768)
dosFile                               FILE,DRIVER('DOS'),CREATE
                                        RECORD
buf                                       STRING(bufSize)
                                        END
                                      END
pos                                   LONG(1)
poslen                                LONG
fileSize                              LONG
str                                   &STRING

  CODE  
  
  dosFile{PROP:Name} = pFileName   
  OPEN(dosFile,20h) !ReadOnly+DenyWrite
  IF ERRORCODE() THEN RETURN NULL.  
  fileSize = BYTES(dosFile)  
  IF NOT fileSize THEN 
    CLOSE(dosFile)
    RETURN NULL
  .
  str &= NEW STRING(fileSize)  
  SEND (dosFile, 'FILEBUFFERS=' & ROUND(fileSize/512, 1))
  LOOP UNTIL pos > fileSize
    GET(dosFile,pos)
    IF pos + bufSize > fileSize
      poslen = fileSize - pos + 1
    ELSE
      poslen = bufSize
    .   
    str [ pos : pos + poslen - 1 ] = dosFile.buf [ 1 : poslen ]
    pos += bufSize    
  .
  CLOSE(dosfile)
  RETURN str
  
FlatSerializer.ParseGroup   PROCEDURE(*GROUP pGroup,LONG pLevel = 1)!,PRIVATE
idx                           LONG
nam                           LIKE(SELF.Fields.Name)
ref                           ANY
pos                           LONG
grref                         &GROUP
gTufoType                     LONG
gTufoAddress                  LONG
gTufoSize                     LONG
  CODE
  
  IF pLevel = 1    
    SELF.GetTufoInfo(pGroup,gTufoType,gTufoAddress,gTufoType)
    IF SELF.GroupTufoType = gTufoType AND SELF.GroupTufoAddress = gTufoAddress AND SELF.GroupTufoSize = gTufoSize  !Don't parse again same group
      SELF.ResolveAliases
      RETURN
    . 
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
    SELF.Fields.UpperName = UPPER(SELF.Fields.Name)    
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
  
  IF pLevel = 1    
    SELF.ResolveAliases
  .
  
FlatSerializer.ResolveAliases   PROCEDURE
idx                               LONG
  CODE  

  !Resolve Alias names to Field names if a file is already loaded
  IF NOT RECORDS(SELF.ColumnNames) THEN RETURN.
  
  !Default link  
  LOOP idx = 1 TO RECORDS(SELF.ColumnNames)
    GET(SELF.ColumnNames,idx)
    SELF.ColumnNames.FieldUpperName = SELF.ColumnNames.UpperName
    PUT(SELF.ColumnNames)
  .  
  IF NOT RECORDS(SELF.FieldsAlias) THEN RETURN.  
  
  !Link field name to column name
  LOOP idx = 1 TO RECORDS(SELF.ColumnNames)
    GET(SELF.ColumnNames,idx)
    !Look for alias
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
    SELF.ColumnNames.FieldUpperName = SELF.Fields.UpperName
    PUT(SELF.ColumnNames)
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
  CODE
  
  IF LEFT(SELF.Fields.Ref,2) = '="' AND RIGHT(SELF.Fields.Ref,1) = '"' !Excel won't quote separators inside formula string constant
    RETURN '="'&SELF.BlankSeparators(SUB(SELF.Fields.Ref,3,LEN(SELF.Fields.Ref)-3))&'"' !Replace separators with ' '
  .  
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
      RETURN SELF.Fields.Ref
    OF DataType:DATE
      RETURN FORMAT(SELF.Fields.Ref,SELF.DatesPicture)
    OF DataType:TIME
      RETURN FORMAT(SELF.Fields.Ref,SELF.TimesPicture)
    ELSE
      !Strings
      IF SELF.AlwaysQuoteStrings OR |
          INSTRING(SELF.ColumnSep,SELF.Fields.Ref,1,1) OR |
          INSTRING(SELF.LineBreakString,SELF.Fields.Ref,1,1) OR |
          INSTRING(SELF.QuoteSymbol,SELF.Fields.Ref,1,1) 
        RETURN SELF.QuoteSymbol & SELF.EscapeQuotes(CLIP(SELF.Fields.Ref)) & SELF.QuoteSymbol
      ELSE
        RETURN CLIP(SELF.Fields.Ref)
      .      
  .
  RETURN ''

FlatSerializer.DeformatColumnValueForField  PROCEDURE()!,STRING,PRIVATE
  CODE  

  CASE SELF.Fields.TufoType
    OF DataType:DATE
      RETURN DEFORMAT(SELF.LineValues.ColumnValues.Value,SELF.DatesPicture)
    OF DataType:TIME
      RETURN DEFORMAT(SELF.LineValues.ColumnValues.Value,SELF.TimesPicture)
    ELSE
      RETURN SELF.LineValues.ColumnValues.Value
  .
  RETURN ''
    
FlatSerializer.DeformatColumnValue  PROCEDURE(LONG pDeformatOptions)!,STRING,PRIVATE
retint                                LONG
retstr                                fsDynString
  CODE  
  
  IF NOT SELF.LineValues.ColumnValues.Value THEN RETURN ''.  
  IF BAND(pDeformatOptions,fs:DeformatDates)
    retint = DEFORMAT(SELF.LineValues.ColumnValues.Value,SELF.DatesPicture)
    IF CLIP(LEFT(FORMAT(retint,SELF.DatesPicture))) = CLIP(LEFT(SELF.LineValues.ColumnValues.Value))
      RETURN retint
    .
  .
  IF BAND(pDeformatOptions,fs:DeformatTimes)
    retint = DEFORMAT(SELF.LineValues.ColumnValues.Value,SELF.TimesPicture)
    IF CLIP(LEFT(FORMAT(retint,SELF.TimesPicture))) = CLIP(LEFT(SELF.LineValues.ColumnValues.Value))
      RETURN retint
    .
  .
  IF SELF.ColumnSep <> ',' AND BAND(pDeformatOptions,fs:DeformatCommas) 
    retstr.set(LEFT(CLIP(SELF.LineValues.ColumnValues.Value)))
    retstr.replace(',','')
    IF NUMERIC(retstr.get())
      RETURN retstr.get()
    .
  .  
  RETURN CLIP(SELF.LineValues.ColumnValues.Value)
  
FlatSerializer.EscapeQuotes PROCEDURE(STRING pText)!,STRING,PRIVATE
value fsDynString
  CODE    
  
  value.set(pText)
  value.replace(SELF.QuoteSymbol,SELF.QuoteSymbol&SELF.QuoteSymbol)
  RETURN value.get()
  
FlatSerializer.UnEscapeQuotes   PROCEDURE(STRING pText)!,STRING,PRIVATE
value                             fsDynString
  CODE  
  
  value.set(pText)  
  value.replace(SELF.QuoteSymbol&SELF.QuoteSymbol,SELF.QuoteSymbol)
  RETURN value.get()
  
FlatSerializer.BlankSeparators  PROCEDURE(STRING pText)!,STRING,PRIVATE  
value                             fsDynString
  CODE
  
  value.set(pText)
  value.replace(SELF.ColumnSep,' ')
  value.replace(SELF.LineBreakString,' ')
  value.replace(SELF.QuoteSymbol,' ')
  RETURN CLIP(value.get())

FlatSerializer.FindSerializeAlias   PROCEDURE()!,STRING
  CODE
  
  CLEAR(SELF.FieldsAlias)
  SELF.FieldsAlias.TufoType = SELF.Fields.TufoType
  SELF.FieldsAlias.TufoAddress = SELF.Fields.TufoAddress
  SELF.FieldsAlias.TufoSize = SELF.Fields.TufoSize
  GET(SELF.FieldsAlias,SELF.FieldsAlias.TufoType,SELF.FieldsAlias.TufoAddress,SELF.FieldsAlias.TufoSize)
  IF NOT ERRORCODE() THEN RETURN SELF.FieldsAlias.Name.
    
  RETURN SELF.Fields.Name

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

fsDynString.set     PROCEDURE(STRING str)
  CODE

  DISPOSE(SELF.s)
  SELF.len = SIZE(str)
  IF NOT SELF.len THEN RETURN.
  SELF.s &= NEW STRING(SELF.len)
  SELF.s = str
  
fsDynString.get           PROCEDURE()!,STRING
  CODE

  IF SELF.s &= NULL THEN RETURN ''.
  RETURN SELF.s

fsDynString.get     PROCEDURE(LONG pstart,LONG pend)!,STRING
  CODE

  IF SELF.s &= NULL THEN RETURN ''.
  IF pstart > SELF.len() OR pend > SELF.len() OR pstart > pend OR pstart < 0 OR pend < 0 THEN RETURN ''.
  RETURN SELF.s[ pstart : pend ]

fsDynString.len     PROCEDURE()!,LONG
  CODE

  IF SELF.s &= NULL THEN RETURN 0.
  RETURN SELF.len

fsDynString.append  PROCEDURE(STRING str)
  CODE

  SELF.set(SELF.get() & str)

fsDynString.append  PROCEDURE(STRING str,STRING sep)
  CODE
  IF SELF.s &= NULL
    SELF.set(str)
  ELSE    
    SELF.set(SELF.get() & sep & str)
  .
  
fsDynString.replace PROCEDURE(STRING pOldString,STRING pNewString)
start                 LONG
pos                   LONG
oldStringLen          LONG
newStringLen          LONG
  CODE    
  IF SELF.s &= NULL THEN RETURN.
  oldStringLen = LEN(pOldString)
  newStringLen = LEN(pNewString)
  start = 1
  LOOP
    pos = INSTRING(pOldString,SELF.s,1,start)
    IF NOT pos THEN BREAK.
    SELF.set( SELF.get(1,pos-1) & pNewString & SELF.get(pos+oldStringLen,SELF.len())) 
    start = pos + newStringLen
  .

fsDynString.Destruct    PROCEDURE
  CODE
  DISPOSE(SELF.s) 
