# Run this knintr::stitch_rmd line below (in the console) for easier communication to other developers.
#   It runs everything below and save the results to an md & html file.
#   Notice the 'sessionInfo()' at the bottom of the output.
# knitr::stitch_rmd(script="./tests/manual/test-varchar.R", output="./tests/manual/stitched-output/test-varchar.md")

rm(list=ls(all=TRUE)) #Clear the memory for any variables set from any previous runs.

# ---- load-packages -----------------------------------------------------------
requireNamespace("RODBC")
requireNamespace("RODBCext")
requireNamespace("testit")

# ---- declare-globals ---------------------------------------------------------
set.seed(234) #To make the results easier to compare.

dsn_13_1 <- "rodbcext-test-13-1" #ODBC Driver 13.1: https://www.microsoft.com/en-us/download/details.aspx?id=53339
dsn_11_0 <- "rodbcext-test-11-0" #ODBC Driver 11: https://www.microsoft.com/en-us/download/details.aspx?id=36434
row_count <- 5L

sql_delete   <- "DELETE FROM dbo.tbl_chracter_test_1"
sql_insert   <- "INSERT INTO dbo.tbl_chracter_test_1 VALUEs (?, ?, ?, ?, ?)"
sql_retrieve <- "SELECT * FROM dbo.tbl_chracter_test_1"

ds_write <- data.frame(
	ID               = seq_len(row_count),
	char_5           = replicate(row_count, paste(sample(letters, size=   5L, replace=T), collapse="")),
	char_255         = replicate(row_count, paste(sample(letters, size= 255L, replace=T), collapse="")),
	char_256         = replicate(row_count, paste(sample(letters, size= 256L, replace=T), collapse="")),
	char_8000        = replicate(row_count, paste(sample(letters, size=8000L, replace=T), collapse="")),
	# char_max       = replicate(row_count, paste(sample(letters, size=8001L, replace=T), collapse="")), #Is there a column/condition that makes sense for max?
	stringsAsFactors = FALSE
)

# ---- test-13-1 ---------------------------------------------------------------
channel <- RODBC::odbcConnect(dsn_13_1)
getSqlTypeInfo("Microsoft SQL Server")
channel_info <- odbcGetInfo(channel)
channel_info["Server_Name"] <- "redacted" #Clear the database name
print(channel_info)

base::tryCatch(
  expr = {
    
    RODBCext::sqlExecute(channel, sql_delete)
    RODBCext::sqlExecute(channel, sql_insert, ds_write)
    
    ds_read_13_1 <- RODBCext::sqlExecute(channel, sql_retrieve, data=NULL, fetch=TRUE, stringsAsFactors=FALSE)
    
  }, finally = {
    RODBC::odbcClose(channel)
    rm(channel)
  }
)

sapply(ds_read_13_1, function(x ) max(nchar(x)))
# > sapply(ds_read_13_1, function(x ) max(nchar(x)))
#        id    char_5  char_255  char_256 char_8000 
#         1         5       255       255      7999 
        
testit::assert("The `id` column should be correct.", identical(ds_read_13_1$id, 1L:5L))

testit::assert("The 5-character column should have.the correct length", all(nchar(ds_read_13_1$char_5)==5L))
testit::assert("The 5-character column should be correct.", identical(ds_read_13_1$char_5, ds_write$char_5))

testit::assert("The 255-character column should have.the correct length", all(nchar(ds_read_13_1$char_255)==255L))
testit::assert("The 255-character column should be correct.", identical(ds_read_13_1$char_255, ds_write$char_255))

#This fails.  All elements are 255 (not 256)
testit::assert("The 256-character column should have.the correct length", all(nchar(ds_read_13_1$char_256)==256L))
testit::assert("The 256-character column should be correct.", identical(ds_read_13_1$char_256, ds_write$char_256))

#This fails.  All elements are 7999
testit::assert("The 8000-character column should have.the correct length", all(nchar(ds_read_13_1$char_8000)==8000L))
testit::assert("The 8000-character column should be correct.", identical(ds_read_13_1$char_8000, ds_write$char_8000))


# ---- test-11-0 ---------------------------------------------------------------
channel <- RODBC::odbcConnect(dsn_11_0)
getSqlTypeInfo("Microsoft SQL Server")
channel_info <- odbcGetInfo(channel)
channel_info["Server_Name"] <- "redacted" #Clear the database name
print(channel_info)

base::tryCatch(
  expr = {
    
    RODBCext::sqlExecute(channel, sql_delete)
    RODBCext::sqlExecute(channel, sql_insert, ds_write)
    
    ds_read_11_0 <- RODBCext::sqlExecute(channel, sql_retrieve, data=NULL, fetch=TRUE, stringsAsFactors=FALSE)
    
  }, finally = {
    RODBC::odbcClose(channel)
    rm(channel)
  }
)

sapply(ds_read_11_0, function(x ) max(nchar(x)))
# > sapply(ds_read_11_0, function(x ) max(nchar(x)))
#        id    char_5  char_255  char_256 char_8000 
#         1         5       255       255      7999 
        
testit::assert("The `id` column should be correct.", identical(ds_read_11_0$id, 1L:5L))

testit::assert("The 5-character column should have.the correct length", all(nchar(ds_read_11_0$char_5)==5L))
testit::assert("The 5-character column should be correct.", identical(ds_read_11_0$char_5, ds_write$char_5))

testit::assert("The 255-character column should have.the correct length", all(nchar(ds_read_11_0$char_255)==255L))
testit::assert("The 255-character column should be correct.", identical(ds_read_11_0$char_255, ds_write$char_255))

#This fails.  All elements are 255 (not 256)
testit::assert("The 256-character column should have.the correct length", all(nchar(ds_read_11_0$char_256)==256L))
testit::assert("The 256-character column should be correct.", identical(ds_read_11_0$char_256, ds_write$char_256))

#This fails.  All elements are 7999
testit::assert("The 8000-character column should have.the correct length", all(nchar(ds_read_11_0$char_8000)==8000L))
testit::assert("The 8000-character column should be correct.", identical(ds_read_11_0$char_8000, ds_write$char_8000))
