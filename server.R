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
  #every 900 seconds.
  autoInvalidate <- reactiveTimer(900000, session)
  #Invalidate and re-execute this reactive expression every time the
  #timer fires.
  observe({
    ##channel
    ##Make sure DSN IS FREE TO OPEN
    withProgress(message = '正在连接数据源',
                 detail = '可能需要花一段时间',
                 value = 0.1,{
                   summary_ch <-
                     odbcConnectExcel2007(
                       '/\\ksa008/shared/Technical/Projects/CKT Spec Summary/Copy of CKT Spec Summary list 2 .xlsx',
                       readOnly = TRUE
                     )
                   #file address alwasys change.use file.exist() to do something.
                   ch <-
                     odbcConnectExcel2007(
                       "/\\ksa008/shared/Production/Schedule_Data/Sharepoint/生管/计划日报表/11年计划日报表汇总/TBM/Dec/TBM Daily Report-2015.xlsx",
                       readOnly = TRUE
                     )
                 })
    
    time <- strftime(Sys.Date(),format = '%D')
    #next day time <- strftime(Sys.Date() + 1,format = '%D')
    #remeber to add a tabpanel to show the next day schedule
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
    
    #fixed number of rows
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
    
    #delete the blank rows of Daydat
    DayDat2 <- subset(DayDat1,!is.na(DayDat1['SPEC']))
    NightDat2 <- subset(NightDat1,!is.na(NightDat1['SPEC']))
    
    #initializtion
    DayRes <- vector(mode = 'list')
    NightRes <- vector(mode = 'list')
    
    #code list
    material.list <-
      c(
        'Innerliner Code','1#Ply Code','2#Ply Code','Bead code','Sidewall code',
        '1# Belt code','2# Belt code','SNOW code'
      )
    
    #foo loop to SQL from EXCEL,maybe could use sapply later
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
          'SNOW code' = 'NULL'
          #add tread here
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
          'SNOW code' = 'NULL'
          #add tread here
        )
        colnames(NightRes[[x]]) <- material.list
      }
    }
    
    #row bind
    DayRes <- do.call(rbind,DayRes)
    NightRes <- do.call(rbind,NightRes)
    
    #share data to all session
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
  #[0-9]+ regular expression,rep 0:9 for at least one time.
  df <- subset(DayDat,strsplit(unlist(DayDat['Machine']),'[0-9]+') == 'FSR')
  dd <- subset(DayDat,strsplit(unlist(DayDat['Machine']),'[0-9]+') == 'DRA')
  dv <- subset(DayDat,strsplit(unlist(DayDat['Machine']),'[0-9]+') == 'VMI')
  nf <- subset(NightDat,strsplit(unlist(NightDat['Machine']),'[0-9]+') == 'FSR')
  nd <- subset(NightDat,strsplit(unlist(NightDat['Machine']),'[0-9]+') == 'DRA')
  nv <- subset(NightDat,strsplit(unlist(NightDat['Machine']),'[0-9]+') == 'VMI')
  
  
  #download handler for different tab
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
   
  #day tabset 
  output$day_FSR <- renderDataTable({
    df[c('Machine','SPEC','Schedule',select1())]
  })
  
  output$day_DRA <- renderDataTable({
    dd[c('Machine','SPEC','Schedule',select1())]
  })
  
  output$day_VMI <- renderDataTable({
    dv[c('Machine','SPEC','Schedule',select1())]
  })

  #night tabset
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
      c('No.','SPEC','$','I.L','1P','2P','Bead','SW','1B','2B','SNOW')
    DayDat
  },options = list(pageLength = 50))
})
