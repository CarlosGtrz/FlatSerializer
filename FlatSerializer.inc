!!! <summary>
!!! Generated class template - SourceClass
!!! </summary>
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

fs:DeformatDates    EQUATE(0001b)
fs:DeformatTimes    EQUATE(0010b)
fs:DeformatCommas   EQUATE(0100b)
fs:DeformatAll      EQUATE(0111b)


FlatSerializer      CLASS,MODULE('FlatSerializer'),LINK('FlatSerializer'),TYPE
Init                  PROCEDURE(<STRING pColumnSep>,<STRING pLineBreakString>,<STRING pQuoteSymbol>)
InitTSV               PROCEDURE
SetColumnSeparator    PROCEDURE(STRING pSep)
SetLineBreakString    PROCEDURE(STRING pStr)
SetQuoteSymbol        PROCEDURE(STRING pSym)
SetDatesPicture       PROCEDURE(STRING pPic)
SetTimesPicture       PROCEDURE(STRING pPic)
SetIncludeHeaders     PROCEDURE(BOOL pVal)
SetAlwaysQuoteStrings PROCEDURE(BOOL pVal)
SetRemovePrefixes     PROCEDURE(BOOL pVal)
SetReadLinesWithoutColumnSeparators   PROCEDURE(BOOL pVal)

!Serialize
AddExcludedFieldByName    PROCEDURE(STRING pField)
AddExcludedFieldByReference   PROCEDURE(*? pField)
SerializeGroupNames   PROCEDURE(*GROUP pGroup),STRING
SerializeGroupValues  PROCEDURE(*GROUP pGroup),STRING
SerializeGroup        PROCEDURE(*GROUP pGroup),STRING
SerializeQueue        PROCEDURE(*QUEUE pQueue),STRING
SerializeFile         PROCEDURE(*FILE pFile,<*KEY pFileKey>),STRING
SerializeGroupToTextFile  PROCEDURE(*GROUP pGroup,STRING pFileName)
SerializeQueueToTextFile  PROCEDURE(*QUEUE pQueue,STRING pFileName)
SerializeFileToTextFile   PROCEDURE(*FILE pFile,STRING pFileName,<*KEY pFileKey>)

!Deserialize
AddFieldAliasByReference  PROCEDURE(*? pField,STRING pAlias)
LoadString            PROCEDURE(STRING pText)
LoadTextFile          PROCEDURE(STRING pFileName)
GetLinesCount         PROCEDURE(),LONG
GetColumnsCount       PROCEDURE(),LONG
GetColumnName         PROCEDURE(LONG pColumnNumber),STRING
GetValueByName        PROCEDURE(STRING pColumnName,LONG pLineNumber = 1,LONG pDeformatOptions = fs:DeformatAll),STRING
DeSerializeToGroup    PROCEDURE(*GROUP pGroup,LONG pLineNumber = 1)
DeSerializeToQueue    PROCEDURE(*QUEUE pQueue)
DeSerializeToFile     PROCEDURE(*FILE pFile)

!Utility
StringToTextFile      PROCEDURE(STRING pStr,STRING pFileName)!,PRIVATE
StringFromTextFile    PROCEDURE(STRING pFileName),*STRING!,PRIVATE

!Private
ParseGroup            PROCEDURE(*GROUP pGroup,LONG pLevel = 1),PRIVATE
IsExcluded            PROCEDURE(),BOOL,PRIVATE
FieldsInGroup         PROCEDURE(*GROUP pGroup),LONG,PRIVATE
FormatFieldValue      PROCEDURE(),STRING,PRIVATE
DeformatColumnValueForField   PROCEDURE(),STRING,PRIVATE
DeformatColumnValue   PROCEDURE(LONG pDeformatOptions),STRING,PRIVATE
EscapeQuotes          PROCEDURE(STRING pText),STRING,PRIVATE
UnEscapeQuotes        PROCEDURE(STRING pText),STRING,PRIVATE
BlankSeparators       PROCEDURE(STRING pText),STRING,PRIVATE
GetTufoInfo           PROCEDURE(*? pAny,*LONG pType,*LONG pAddress,*LONG pSize),PRIVATE
Free                  PROCEDURE(fsFieldsQueue pQueue),PRIVATE
FreeLineValues        PROCEDURE,PRIVATE
DebugView             PROCEDURE(STRING pStr)
Construct             PROCEDURE
Destruct              PROCEDURE

!Private Fields
ColumnSep             CSTRING(5),PRIVATE
LineBreakString       CSTRING(5),PRIVATE
QuoteSymbol           CSTRING(5),PRIVATE
DatesPicture          STRING(10),PRIVATE
TimesPicture          STRING(10),PRIVATE
IncludeHeaders        BOOL,PRIVATE
AlwaysQuoteStrings    BOOL,PRIVATE
RemovePrefixes        BOOL,PRIVATE
ReadLinesWithoutColumnSeparators  BOOL,PRIVATE
GroupTufoType         LONG,PRIVATE
GroupTufoAddress      LONG,PRIVATE
GroupTufoSize         LONG,PRIVATE
ExcludedFields        &fsFieldsQueue,PRIVATE
Fields                &fsFieldsQueue,PRIVATE
FieldsAlias           &fsFieldsQueue,PRIVATE
ColumnNames           &fsColumnNames,PRIVATE
LineValues            &fsLineValues,PRIVATE
                    END

fsFieldsQueue       QUEUE,TYPE
Name                  STRING(60)
UpperName             STRING(60)
Ref                   ANY
IsGroup               LONG
Level                 LONG
TufoType              LONG
TufoAddress           LONG
TufoSize              LONG
                    END
