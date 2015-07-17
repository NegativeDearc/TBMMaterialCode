library(shiny)
library(RODBC)

##channel
summary_ch <- odbcConnect(dsn = 'CKT SPEC SUMMARY')
ch <- odbcConnectExcel2007("P:/Production/Schedule_Data/Sharepoint/生管/计划日报表/11年计划日报表汇总/TBM/Dec/TBM Daily Report--2015.xlsx")

time <- strftime(Sys.Date(),format = '%D')
#next day time <- strftime(Sys.Date() + 1,format = '%D')
time <- as.numeric(strsplit(time,'/')[[1]])
time <- paste0(time[1],'#',time[2],'$')
spec.no <- sqlQuery(ch,paste0("select \"F3\" from","\"",time,"\""))
#只取排产部分
spec.no <- as.character(spec.no[6:120,])
FSR_names <- rep(paste0('FSR',1:12),each = 3)
DRA_names <- rep(paste0('DRA',1:7),each = 5)
VMI_names <- rep(paste0('VMI',1:11),each = 4)
Machine <- c(FSR_names,DRA_names,VMI_names)
dat1 <- data.frame(Machine = Machine,SPEC = spec.no,stringsAsFactors = FALSE)
dat2 <- subset(dat1,!is.na(dat1['SPEC']))
res <- vector(mode = 'list')
res2 <- vector(mode = 'list')

material.list <- c('Innerliner Code','1#Ply Code','2#Ply Code','BF code','Sidewall code','Tread code',
                   '1# Belt code','2# Belt code')
for(x in 1:nrow(dat2)){
  res[[x]] <- sqlQuery(summary_ch,paste('SELECT * ',"FROM \"CKT spec summary$\"","WHERE \"Spec_No\" = ",dat2['SPEC'][x,1]))[material.list]
  if(nrow(res[[x]]) == 0){
    res[[x]] <- as.data.frame(matrix(0,nrow = 1,ncol = 8))
  }
}
res <- do.call(rbind,res)
#已经完整的数据结构
dat3 <- cbind(dat2,res)
##server
shinyServer(function(input, output){
  #table1
  output$table1 <- renderDataTable({
   select <- reactive(input$checkbox)
   dat3[c('Machine','SPEC',select())]
  })
  #table
  output$table <- renderDataTable({
    colnames(dat3) <- c('机台','SPEC','内面胶','1号帘布','2号帘布','三角胶','胎边','胎面','1层环带','2层环带')
    dat3
   },options = list(pageLength = 50))
  odbcCloseAll()  
})
  