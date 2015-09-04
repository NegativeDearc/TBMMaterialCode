if(!require('shiny')) {
  install.packages('shiny')
}
if (!require('RODBC')) {
  install.packages('RODBC')
}
if (!require('networkD3')) {
  install.packages('networkD3')
}
##server
shinyServer(function(input, output,session) {
  #every 1000 seconds.
  autoInvalidate <- reactiveTimer(1000000, session)
  #Invalidate and re-execute this reactive expression every time the
  #timer fires.
  observe({
    #odbc channels
    #Make sure DSN IS FREE TO OPEN and have enough permission
    withProgress(message = '正在连接数据源',
                 detail = '可能需要花一段时间',
                 value = 25,{
                   summary_ch <-
                     odbcConnectExcel2007(
                       '/\\ksa008/shared/Technical/Projects/CKT Spec Summary/Copy of CKT Spec Summary list 2 .xlsx',
                       readOnly = TRUE
                     )
                   ch <-
                     odbcConnectExcel2007(
                       "/\\ksa008/shared/Production/Schedule_Data/Sharepoint/生管/计划日报表/15年计划日报表汇总/TBM/TBM plan/TBM Daily Report-2015(Sep).xlsx",
                       readOnly = TRUE
                     )
                   #This file is a shared EXCEL,when the editor trying to save and mean time 
                   #the odbc connector is connected.File will failed to save with error
                   #'The cell is locked,try this command later.'
                   #So add a while Loop,sleep 15 seconds to let the file save successful.
                   #If 15 sec is not enough,edit it when needed.
                   while(ch == -1L){
                     Sys.sleep(15)
                     odbcReConnect(ch)
                   }
                 })
    
    time <- strftime(Sys.Date(),format = '%D')
    #next day time <- strftime(Sys.Date() + 1,format = '%D')
    time <- as.numeric(strsplit(time,'/')[[1]])
    #sheet name of EXCEL endwith '$'
    time <- paste0(time[1],'#',time[2],'$')
    #columns names in EXCEL Begain with F
    SpecDay <-
      sqlQuery(ch,paste0("select \"F3\" from","\"",time,"\""))
    DaySchedule <-
      sqlQuery(ch,paste0("select \"F4\" from","\"",time,"\""))
    SpecNight <-
      sqlQuery(ch,paste0("select \"F9\" from","\"",time,"\""))
    NightSchedule <-
      sqlQuery(ch,paste0("select \"F10\" from","\"",time,"\""))
    
    #Day shift & Nightshift
    SpecDay <- as.character(SpecDay[6:120,])
    SpecNight <- as.character(SpecNight[6:120,])
    DaySchedule <- as.character(DaySchedule[6:120,])
    NightSchedule <- as.character(NightSchedule[6:120,])
    
    FSR_names <- rep(paste0('FSR',1:12),each = 3)
    DRA_names <- rep(paste0('DRA',1:7),each = 5)
    VMI_names <- rep(paste0('VMI',1:11),each = 4)
    Machine <- c(FSR_names,DRA_names,VMI_names)
    
    #Make sure str in data.frame not convert to factors
    DayDat1 <- data.frame(
      Machine = Machine,
      SPEC = SpecDay,
      Schedule = DaySchedule,
      stringsAsFactors = FALSE
    )
    NightDat1 <- data.frame(
      Machine = Machine,
      SPEC = SpecNight,
      Schedule = NightSchedule,
      stringsAsFactors = FALSE
    )
    
    #delete the blank rows
    DayDat2 <- subset(DayDat1,!is.na(DayDat1['SPEC']))
    NightDat2 <- subset(NightDat1,!is.na(NightDat1['SPEC']))
    
    #initialization
    DayRes <- vector(mode = 'list')
    NightRes <- vector(mode = 'list')
    
    #The colnames of the summary list(May change anytime)
    material.list <-
      c(
        'Innerliner Code','1#Ply Code','2#Ply Code','Bead code','Sidewall code',
        '1# Belt code','2# Belt code','SNOW code','Tread code'
      )
    
    #for loop to SQL data
    for (x in 1:nrow(DayDat2)) {
      DayRes[[x]] <-
        sqlQuery(
          summary_ch,paste(
            'SELECT * ',"FROM \"CKT spec summary$\"","WHERE \"Spec_No\" = ",DayDat2['SPEC'][x,1]
          )
        )[material.list]
      if (nrow(DayRes[[x]]) == 0) {
        DayRes[[x]] <- data.frame(
          'Innerliner Code' = 'NULL',
          '1#Ply Code' = 'NULL',
          '2#Ply Code' = 'NULL',
          'Bead code' = 'NULL',
          'Sidewall code' = 'NULL',
          '1# Belt code' = 'NULL',
          '2# Belt code' = 'NULL',
          'SNOW code' = 'NULL',
          'Tread code' = 'NULL'
        )
        colnames(DayRes[[x]]) <- material.list
      }
    }
    
    for (x in 1:nrow(NightDat2)) {
      NightRes[[x]] <-
        sqlQuery(
          summary_ch,paste(
            'SELECT * ',"FROM \"CKT spec summary$\"","WHERE \"Spec_No\" = ",NightDat2['SPEC'][x,1]
          )
        )[material.list]
      if (nrow(NightRes[[x]]) == 0) {
        NightRes[[x]] <- data.frame(
          'Innerliner Code' = 'NULL',
          '1#Ply Code' = 'NULL',
          '2#Ply Code' = 'NULL',
          'Bead code' = 'NULL',
          'Sidewall code' = 'NULL',
          '1# Belt code' = 'NULL',
          '2# Belt code' = 'NULL',
          'SNOW code' = 'NULL',
          'Tread code' = 'NULL'
        )
        colnames(NightRes[[x]]) <- material.list
      }
    }
    
    #close odbc channel,NEVER forget it.
    odbcClose(ch)
    odbcClose(summary_ch)
    DayRes <- do.call(rbind,DayRes)
    NightRes <- do.call(rbind,NightRes)
    
    #share data with all sessions
    DayDat <<- cbind(DayDat2,DayRes)
    NightDat <<- cbind(NightDat2,NightRes)
    
    autoInvalidate()
    cat('Data Prepare Ready...\n')
  })
  #select box
  select2 <-
    reactive(input$checkbox2)
  select1 <-
    reactive(input$checkbox1)
  #data subsets
  df <- subset(DayDat,strsplit(unlist(DayDat['Machine']),'[0-9]+') == 'FSR')
  dd <- subset(DayDat,strsplit(unlist(DayDat['Machine']),'[0-9]+') == 'DRA')
  dv <- subset(DayDat,strsplit(unlist(DayDat['Machine']),'[0-9]+') == 'VMI')
  nf <- subset(NightDat,strsplit(unlist(NightDat['Machine']),'[0-9]+') == 'FSR')
  nd <- subset(NightDat,strsplit(unlist(NightDat['Machine']),'[0-9]+') == 'DRA')
  nv <- subset(NightDat,strsplit(unlist(NightDat['Machine']),'[0-9]+') == 'VMI')
  
  #dowmload sidewall
  output$sw_day <- 
    downloadHandler(
      filename = function() {
        paste(format(Sys.time(),'%y%m%d%H%M%S'),'sw_day','.csv',sep = '')
      },
      content = function(file) {
        write.csv(rbind(df,dv)[c('Machine','SPEC','Schedule','Sidewall code')],file)
      }
    )
  
  output$sw_night <- 
    downloadHandler(
      filename = function() {
        paste(format(Sys.time(),'%y%m%d%H%M%S'),'sw_night','.csv',sep = '')
      },
      content = function(file) {
        write.csv(rbind(nf,nv)[c('Machine','SPEC','Schedule','Sidewall code')],file)
      }
    )
  #download handler
  output$download_day <-
    downloadHandler(
      filename = function() {
        paste(format(Sys.time(),'%y%m%d%H%M%S'),input$day,'.csv',sep = '')
      },
      content = function(file) {
        ##add tabPanel day/night here
        if (input$day == 'day_FSR') {
          write.csv(df[c('Machine','SPEC','Schedule',select1())],file)
        } 
        if (input$day == 'day_DRA'){
          write.csv(dd[c('Machine','SPEC','Schedule',select1())],file)
        }
        if (input$day == 'day_VMI'){
          write.csv(dv[c('Machine','SPEC','Schedule',select1())],file)
        }
      }
    )
  #download handler
  output$download_night <-
    downloadHandler(
      filename = function() {
        paste(format(Sys.time(),'%y%m%d%H%M%S'),input$night,'.csv',sep = '')
      },
      content = function(file) {
        ##add tabPanel day/night here
        if (input$night == 'night_FSR') {
          write.csv(nf[c('Machine','SPEC','Schedule',select2())],file)
        } 
        if (input$night == 'night_DRA'){
          write.csv(nd[c('Machine','SPEC','Schedule',select2())],file)
        }
        if (input$night == 'night_VMI'){
          write.csv(nv[c('Machine','SPEC','Schedule',select2())],file)
        }
      }
    )
  #networkD3
  output$network <- renderSimpleNetwork({
    simpleNetwork(
      DayDat,'Machine','1#Ply Code',fontSize = 14,nodeColour = 'orange',zoom = TRUE
    )
  })

  #day
  output$day_FSR <- renderDataTable({
    df[c('Machine','SPEC','Schedule',select1())]
  })
  
  output$day_DRA <- renderDataTable({
    dd[c('Machine','SPEC','Schedule',select1())]
  })
  
  output$day_VMI <- renderDataTable({
    dv[c('Machine','SPEC','Schedule',select1())]
  })

  #night
  output$night_FSR <- renderDataTable({
    nf[c('Machine','SPEC','Schedule',select2())]
  })
  
  output$night_DRA <- renderDataTable({
    nd[c('Machine','SPEC','Schedule',select2())]
  })
  
  output$night_VMI <- renderDataTable({
    nv[c('Machine','SPEC','Schedule',select2())]
  })
  
  #daysummary
  output$summary <- renderDataTable({
    colnames(DayDat) <-
      c('No.','SPEC','$','I.L','1P','2P','Bead','SW','1B','2B','SNOW','TREAD')
    DayDat
  },options = list(pageLength = 50))
})
