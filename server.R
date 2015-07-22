library(shiny)
library(RODBC)

##server
shinyServer(function(input, output,session){
  #every 200 seconds.
  autoInvalidate <- reactiveTimer(200000, session)
  #Invalidate and re-execute this reactive expression every time the
  #timer fires.
  observe({
    ##channel
    ##Make sure DSN IS FREE TO OPEN
    withProgress(message = '正在连接数据源',
                 detail = '可能需要花一段时间',
                 value = 0.1,{
      summary_ch <- odbcConnect(dsn = 'CKT SPEC SUMMARY')
      ch <- odbcConnectExcel2007("P:/Production/Schedule_Data/Sharepoint/生管/计划日报表/11年计划日报表汇总/TBM/Dec/TBM Daily Report-2015.xlsx",
                                 readOnly = TRUE)
    })
    
    time <- strftime(Sys.Date(),format = '%D')
    #next day time <- strftime(Sys.Date() + 1,format = '%D')
    time <- as.numeric(strsplit(time,'/')[[1]])
    #sheet name of EXCEL endwith '$'
    time <- paste0(time[1],'#',time[2],'$')
    #columns names in EXCEL Begain with F
    SpecDay <- sqlQuery(ch,paste0("select \"F3\" from","\"",time,"\""))
    SpecNight <- sqlQuery(ch,paste0("select \"F9\" from","\"",time,"\""))
    #Day shift & Nightshift
    SpecDay <- as.character(SpecDay[6:120,])
    SpecNight <- as.character(SpecNight[6:120,])
      
    FSR_names <- rep(paste0('FSR',1:12),each = 3)
    DRA_names <- rep(paste0('DRA',1:7),each = 5)
    VMI_names <- rep(paste0('VMI',1:11),each = 4)
    Machine <- c(FSR_names,DRA_names,VMI_names)
    
    #Make sure str in data.frame not convert to factors
    DayDat1 <- data.frame(Machine = Machine,
                          SPEC = SpecDay,
                          stringsAsFactors = FALSE)
    NightDat1 <- data.frame(Machine = Machine,
                            SPEC = SpecNight,
                            stringsAsFactors = FALSE)
    DayDat2 <- subset(DayDat1,!is.na(DayDat1['SPEC']))
    NightDat2 <- subset(NightDat1,!is.na(NightDat1['SPEC']))
      
    DayRes <- vector(mode = 'list')
    NightRes <- vector(mode = 'list')
      
    material.list <- c('Innerliner Code','1#Ply Code','2#Ply Code','Bead code','Sidewall code','Tread code',
                         '1# Belt code','2# Belt code','SNOW code')
      
    for(x in 1:nrow(DayDat2)){
      DayRes[[x]] <- sqlQuery(summary_ch,paste('SELECT * ',"FROM \"CKT spec summary$\"","WHERE \"Spec_No\" = ",DayDat2['SPEC'][x,1]))[material.list]
      print(nrow(DayRes[[x]]))
      if(nrow(DayRes[[x]]) == 0){
        DayRes[[x]] <- data.frame('Innerliner Code' = 'NULL',
                                  '1#Ply Code' = 'NULL',
                                  '2#Ply Code' = 'NULL',
                                  'Bead code' = 'NULL',
                                  'Sidewall code' = 'NULL',
                                  'Tread code' = 'NULL',
                                  '1# Belt code' = 'NULL',
                                  '2# Belt code' = 'NULL',
                                  'SNOW code' = 'NULL')
        colnames(DayRes[[x]]) <- c('Innerliner Code','1#Ply Code','2#Ply Code','Bead code','Sidewall code','Tread code',
                                    '1# Belt code','2# Belt code','SNOW code')
      }
    }
      
    for(x in 1:nrow(NightDat2)){
      NightRes[[x]] <- sqlQuery(summary_ch,paste('SELECT * ',"FROM \"CKT spec summary$\"","WHERE \"Spec_No\" = ",NightDat2['SPEC'][x,1]))[material.list]
      print(nrow(NightRes[[x]]))
      if(nrow(NightRes[[x]]) == 0){
        NightRes[[x]] <- data.frame('Innerliner Code' = 'NULL',
                                    '1#Ply Code' = 'NULL',
                                    '2#Ply Code' = 'NULL',
                                    'Bead code' = 'NULL',
                                    'Sidewall code' = 'NULL',
                                    'Tread code' = 'NULL',
                                    '1# Belt code' = 'NULL',
                                    '2# Belt code' = 'NULL',
                                    'SNOW code' = 'NULL')
        colnames(NightRes[[x]]) <- c('Innerliner Code','1#Ply Code','2#Ply Code','BF code','Sidewall code','Tread code',
                                      '1# Belt code','2# Belt code','SNOW code')
      }
    }

    
    
    DayRes <- do.call(rbind,DayRes)
    NightRes <- do.call(rbind,NightRes)
    
    DayDat <<- cbind(DayDat2,DayRes)
    NightDat <<- cbind(NightDat2,NightRes)
    odbcCloseAll()
    
    autoInvalidate()
  })
  #table1
  output$table1 <- renderDataTable({
    select <- reactive(input$checkbox)
    DayDat[c('Machine','SPEC',select())]
  })
  #table
  output$table <- renderDataTable({
    colnames(DayDat) <- c('No.','SPEC','I.L','1 PLY','2 PLY','Bead','SW','TD','1 Belt','2 Belt','SNOW')
    DayDat
  },options = list(pageLength = 50))
  #table_night
  output$table_night <- renderDataTable({
    select <- reactive(input$checkbox)
    NightDat[c('Machine','SPEC',select())]
  })
  #time
#   output$currentTime <- renderText({
#     invalidateLater(1000,session)
#     paste(format(Sys.time(),'%H:%M:%S'))
#   })
})
