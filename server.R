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
  #every 2700 seconds.
  autoInvalidate <- reactiveTimer(2700000, session)
  #Invalidate and re-execute this reactive expression every time the
  #timer fires.
  observe({
    #use regular expression to extract the file name------added 2015/10/31
    base_path <- '/\\ksa008/shared/Production/Schedule_Data/Sharepoint/生管/计划日报表/15年计划日报表汇总/TBM/TBM plan/'
    file_name <- list.files(base_path)
    month <- as.numeric(format(Sys.time(),'%m'))#chinese location format '%b' get '十月'
    month_abb <- month.abb[month]
    re.test <- grepl(paste0('^(tbm)+.+',month_abb,'+.+.xlsx$'),file_name,ignore.case = TRUE)
    #grepl('^(tbm)+.+Nov+.+.xlsx$',filename,ignore.case = TRUE)
    if(!any(re.test)){
      month_abb <- month.abb[month-1]
      re.test <- grepl(paste0('^(tbm)+.+',month_abb,'+.+.xlsx$'),file_name,ignore.case = TRUE)
    }
    #incase exist 2 files match the regexp ,choose the first one
    path <- paste0(base_path,file_name[re.test][1])
    #odbc channels
    #Make sure DSN IS FREE TO OPEN and have enough permission
    withProgress(message = 'Connecting to data sources...\n',
                 detail = 'May take a little while.',
                 value = 25,{
                   summary_ch <-
                     odbcConnectExcel2007(
                       '/\\ksa008/shared/Technical/Projects/CKT Spec Summary/CKT Spec Summary list 2_Sheldon.xlsx',
                       readOnly = TRUE
                     )
                   #This file is a shared EXCEL,when the editor trying to save and mean time 
                   #the odbc connector is connected.File will failed to save with error
                   #'The cell is locked,try this command later.'
                   #So add a while Loop,sleep 15 seconds to let the file save successful.
                   bool = 1
                   while(bool){
                     tryCatch(
                       ch <- odbcConnectExcel2007(path,readOnly = TRUE),
                     error = function(e){
                       cat(conditionMessage(e),'\n')
                       odbcCloseAll()
                       for(i in 12:1){
                         Sys.sleep(1)
                         cat('System will recover',i,'..seconds later.\n')
                       }})
                     if(ch != -1L){
                       bool = 0
                     }
                   }
                 })
    
    time <- strftime(Sys.Date(),format = '%D')
    #next day time <- strftime(Sys.Date() + 1,format = '%D')
    time <- as.numeric(strsplit(time,'/')[[1]])
    #sheet name of EXCEL endwith '$'
    time <- paste0(time[1],'#',time[2],'$')
    #columns names in EXCEL Begain with F
    test <- sqlQuery(ch,paste0("select \"F1\" from","\"",time,"\""))
    if(is.data.frame(test)){
      SpecDay <-
        sqlQuery(ch,paste0("select \"F3\" from","\"",time,"\""))
      DaySchedule <-
        sqlQuery(ch,paste0("select \"F4\" from","\"",time,"\""))
      SpecNight <-
        sqlQuery(ch,paste0("select \"F9\" from","\"",time,"\""))
      NightSchedule <-
        sqlQuery(ch,paste0("select \"F10\" from","\"",time,"\""))
    } else {
      t <- data.frame(t = rep('9999',145))
      SpecDay <- DaySchedule <- SpecNight <- NightSchedule <- t
    }
    
    #Day shift & Nightshift
    row_length <- 6:150
    SpecDay <- as.numeric(as.character(SpecDay[row_length,]))
    #debug 2015-9-21
    #SpecNight is a collect of number,
    #if the programm scap some non-number values like chinese
    #the SQL Loop will cause problems,the app will down.
    SpecNight <- as.numeric(as.character(SpecNight[row_length,]))
    DaySchedule <- as.character(DaySchedule[row_length,])
    NightSchedule <- as.character(NightSchedule[row_length,])
    
    #12*4+7*6+11*5 =145
    FSR_names <- rep(paste0('FSR',1:12),each = 4)
    DRA_names <- rep(paste0('DRA',1:7),each = 6)
    VMI_names <- rep(paste0('VMI',1:11),each = 5)
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
          'Innerliner Code' = '',
          '1#Ply Code' = '',
          '2#Ply Code' = '',
          'Bead code' = '',
          'Sidewall code' = '',
          '1# Belt code' = '',
          '2# Belt code' = '',
          'SNOW code' = '',
          'Tread code' = ''
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
          'Innerliner Code' = '',
          '1#Ply Code' = '',
          '2#Ply Code' = '',
          'Bead code' = '',
          'Sidewall code' = '',
          '1# Belt code' = '',
          '2# Belt code' = '',
          'SNOW code' = '',
          'Tread code' = ''
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
    cat('Data Prepare Ready...',format(Sys.time(),'%m-%d %H:%M:%S'),'\n')
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
        write.table(Sys.time(),file,append = TRUE,col.names = FALSE)
      }
    )
  
  output$sw_night <- 
    downloadHandler(
      filename = function() {
        paste(format(Sys.time(),'%y%m%d%H%M%S'),'sw_night','.csv',sep = '')
      },
      content = function(file) {
        write.csv(rbind(nf,nv)[c('Machine','SPEC','Schedule','Sidewall code')],file)
        write.table(Sys.time(),file,append = TRUE,col.names = FALSE)
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
          write.table(Sys.time(),file,append = TRUE,col.names = FALSE)
        } 
        if (input$day == 'day_DRA'){
          write.csv(dd[c('Machine','SPEC','Schedule',select1())],file)
          write.table(Sys.time(),file,append = TRUE,col.names = FALSE)
        }
        if (input$day == 'day_VMI'){
          write.csv(dv[c('Machine','SPEC','Schedule',select1())],file)
          write.table(Sys.time(),file,append = TRUE,col.names = FALSE)
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
          write.table(Sys.time(),file,append = TRUE,col.names = FALSE)
        } 
        if (input$night == 'night_DRA'){
          write.csv(nd[c('Machine','SPEC','Schedule',select2())],file)
          write.table(Sys.time(),file,append = TRUE,col.names = FALSE)
        }
        if (input$night == 'night_VMI'){
          write.csv(nv[c('Machine','SPEC','Schedule',select2())],file)
          write.table(Sys.time(),file,append = TRUE,col.names = FALSE)
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
