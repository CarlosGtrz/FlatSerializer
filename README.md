# Flat Serializer
A class for serializing and deserializing Clarion structures to Comma (or Tab) Separated Values.

## *Introduction*

To serialize a queue to a text file:
```
myQ QUEUE,PRE(myQ)
id    LONG
Name  STRING(30)
Date  DATE
Time  TIME
    END

fs FlatSerializer

  CODE
  ...
  fs.Init
  fs.SerializeQueueToTextFile(myQ,'testqueue.csv')
```
The resulting `testqueue.csv` text file will look like this:
```
ID,NAME,DATE,TIME
5,"Some Name",2021-07-30,18:45:56
7,"Another Name",2021-12-16,08:12:34
```
To load the same text file to a queue:

```
  FREE(myQ)
  fs.Init
  fs.LoadTextFile('testqueue.csv')
  fs.DeSerializeToQueue(myQ)
```

You can also query a value in a particular value by name and line number:

```
  fs.Init
  fs.LoadTextFile('testqueue.csv')
  loc:name = fs.GetValueByName('Name',2) !Column "NAME", line 2: "Another name"
```

Some of the features:

* Serializes groups, queues and files to a string or text file.
* Deserializes a string or text file to groups, queues or files.
* Can read the value of any column by name and line number.
* Handles new lines, commas (or tabs) and escaped (doubled) quotes inside quoted strings.
* Can be configured to use tabs instead of commas, or alternative line break and quote symbols.
* Detects the data type of fields (number, string, date or time) and formats them (with configurable date and time pictures).
* When serializing, fields in the structure can be excluded by name or by reference.
* When deserializing, fields in the structure can have multiple aliases.
* Handles `NAME()` with "extended | attributes".
* Removes prefixes by default.
* Can be configured to use quotes in strings only when needed (the string contains new lines or commas).
  
  
## *Install*
Copy `FlatSerializer.clw` and `FlatSerializer.inc` to the app folder or a folder in your `.red` file, like `Accessory\libsrc\win`.

## *Use*
Add to a global data embed (like _After Global INCLUDEs_) the line:

    INCLUDE('FlatSerializer.inc'),ONCE
    
In your procedure or routine, declare an instance, and start coding:
```
fs FlatSerializer
  CODE
  fs.Init
  fs.LoadTextFile('testqueue.csv')
  fs.DeSerializeToQueue(myQ)
```
## *Methods*

## Initialization
```
Init  
Init (<STRING pColumnSep>,<STRING pLineBreakString>,<STRING pQuoteSymbol>)
InitTSV
```    
Initializes the instance.

*Parameters*
* ColumnSep: String to use to separate columns. Default is `','` (comma)
* LineBreakString: String to use to separate lines. Default is `'<13,10>'` (cr/lf)
* QuoteSymbol: Symbol to use to quote strings. Default is `'"'` (double quote)

Method `InitTSV` configures the instance to handle _Tab Separated Values_, is equivalent to:
```
fs.Init('<9>')
fs.SetAlwaysQuoteStrings(FALSE)
```

## Configuration
```
SetColumnSeparator (STRING)
SetLineBreakString (STRING)
SetQuoteSymbol (STRING)
```
Change defaults form column separator, line break and quotes. Defaults are `',' ` `'<13,10>'` and `'"'`.


```
SetDatesPicture (STRING)
SetTimesPicture (STRING)
```
Change default pictures for dates and times. Defaults are `'@D10-B'`
(yyyy-mm-dd) and `'@T04B'` (hh:mm:ss).

```
SetIncludeHeaders (BOOL)
SetAlwaysQuoteStrings (BOOL)
SetRemovePrefixes (BOOL)
SetReadLinesWithoutColumnSeparators (BOOL)
```
Change the behavior of the instance:
* Inclue Headers (default `TRUE`): If the serialized string or file should include the column names in the first line
* Always Quote Strings (default `TRUE`): If the string fields should always be enclosed with quote symbols. If set to `FALSE`, quotes are only used if the string includes a comma or new line
* Remove Prefixes (default `TRUE`): If the structure's prefix should be removed from the field name
* ReadLinesWithoutColumnSeparators (default `FALSE`): When set to the default `FALSE`, the class will ignore lines that don't have at least one comma. Useful if the file include titles or documentation in the first few lines. Should be set to `TRUE` if reading files with only one column.

## Serialization
```
AddExcludedFieldByName (STRING pField)
AddExcludedFieldByReference (*? pField)
```
Excluded fields in group or queue from the output.

```
SerializeGroupNames (*GROUP pGroup),STRING
```
Returns a line with the names of the columns based on the group structure declaration.

```
SerializeGroupValues (*GROUP pGroup),STRING
```
Returns a line with the values  of the columns based on the group structure.

```
SerializeGroup (*GROUP pGroup),STRING
SerializeQueue (*QUEUE pQueue),STRING
SerializeFile (*FILE pFile,<*KEY pFileKey>),STRING
```
Returns a string with headers and values based on the passed Clarion structure.

* FileKey (default first key in the file declaration): Key to use to read the file.

```
SerializeGroupToTextFile (*GROUP pGroup,STRING pFileName)
SerializeQueueToTextFile (*QUEUE pQueue,STRING pFileName)
SerializeFileToTextFile (*FILE pFile,STRING pFileName,<*KEY pFileKey>)
```
Creates a text file with headers and values based on the passed Clarion structure.

* FileKey (default first key in the file declaration): Key to use to read the file.

## Deserialization
```
AddFieldAliasByReference (*? pField,STRING pAlias)
```
Add an alternative name to a field. Useful if the header of a column includes spaces, or can have different names.

```
LoadString (STRING pText)
LoadTextFile (STRING pFileName)
```
Load and parse a string or text file. Should be called before deserializing of before getting values.

```
GetLinesCount (),LONG
```
Number of lines with values loaded.

```
GetValueByName (STRING pColumnName,LONG pLineNumber = 1,LONG pDeformatOptions = fs:DeformatAll),STRING
```
Returns a string with the value of the named column at a particular line number.
* DeformatOptions: One or more flags: `fs:DeformatDates`, `fs:DeformatTimes`, `fs:DeformatCommas`, `fs:DeformatAll` or `fs:DeformatNothing`

Example:
```
  fs.Init
  fs.LoadTextFile('testqueue.csv')
  LOOP lin = 1 TO fs.GetLinesCount()
    loc:name = fs.GetValueByName('Name',lin,fs:DeformatCommas) !remove commas from numbers, leave dates and times as is
  END  
```

```
GetColumnsCount (),LONG
```
Number of columns loaded.

```
GetColumnName (STRING pColumnNumber),STRING
```
Returns a string with the name of the column.

Example:
```
  fs.Init
  fs.LoadTextFile('testqueue.csv')
  LOOP col = 1 TO fs.GetColumnsCount()
    loc:colname = fs.GetColumnName(col)
  END  
```

```
DeSerializeToGroup (*GROUP pGroup,LONG pLineNumber = 1)
DeSerializeToQueue (*QUEUE pQueue)
DeSerializeToFile (*FILE pFile)
```
Fills the fields in the structure with the corresponding loaded column values and, for queues and files, adds a new record for each line.

## Utility
```
DebugView (STRING pStr)
```
Writes string to debug output.

