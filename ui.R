library(shiny)

shinyUI(fluidPage(
  #title
  titlePanel(strong('TBM WIP Code Summary'),windowTitle = 'WIP Code'),
  #tabset
  tabsetPanel(id = 'tab',
              tabPanel('Dayshift',value = 'Dayshift',icon = icon('sun-o'),
                       #fluidpage with fluidpage
                       fluidPage(
                         hr(),
                         sidebarPanel(
                           width = 2,
                           helpText(
                             '本程序由',br(),
                             strong('技术部'),br(),
                             '提供支持',
                             br(),
                             em('Tel:',br(),
                                '18260279625')
                           ),
                           checkboxGroupInput(
                             "checkbox1",
                             choices = list(
                               '内面胶' = 'Innerliner Code',
                               '1号帘布' = '1#Ply Code',
                               '2号帘布' = '2#Ply Code',
                               '胎圈' = 'Bead code',
                               '胎边' = 'Sidewall code',
                               '1层环带' = '1# Belt code',
                               '2层环带' = '2# Belt code',
                               'SNOW' = 'SNOW code'
                             ),
                             label = '请选择项目(可多选)'
                           ),
                           downloadButton('download_day',label = '下载')
                         ),
                         mainPanel(
                           #sub tabset
                           tabsetPanel(id = 'day',
                             tabPanel('FSR',value = 'day_FSR',icon = icon('list-alt'),dataTableOutput('day_FSR')),
                             tabPanel('DRA',value = 'day_DRA',icon = icon('list-alt'),dataTableOutput('day_DRA')),
                             tabPanel('VMI',value = 'day_VMI',icon = icon('list-alt'),dataTableOutput('day_VMI'))
                           )
                         )
                       )
              ),
              tabPanel('Nightshift',value = 'Nightshift',icon = icon('moon-o'),
                       fluidPage(
                         hr(),
                         sidebarPanel(
                           width = 2,
                           helpText(
                             '本程序由',br(),
                             '技术部',br(),
                             '提供支持',
                             br(),
                             em('Tel:',br(),
                                '18260279625')
                           ),
                           checkboxGroupInput(
                             "checkbox2",
                             choices = list(
                               '内面胶' = 'Innerliner Code',
                               '1号帘布' = '1#Ply Code',
                               '2号帘布' = '2#Ply Code',
                               '胎圈' = 'Bead code',
                               '胎边' = 'Sidewall code',
                               '1层环带' = '1# Belt code',
                               '2层环带' = '2# Belt code',
                               'SNOW' = 'SNOW code'
                             ),
                             label = '请选择项目(可多选)'
                           ),
                           downloadButton('download_night',label = '下载')
                         ),
                         mainPanel(
                           #sub tabset
                           tabsetPanel(id = 'night',
                             tabPanel('FSR',value = 'night_FSR',icon = icon('list-alt'),dataTableOutput('night_FSR')),
                             tabPanel('DRA',value = 'night_DRA',icon = icon('list-alt'),dataTableOutput('night_DRA')),
                             tabPanel('VMI',value = 'night_VMI',icon = icon('list-alt'),dataTableOutput('night_VMI'))
                           )
                         )
                       )
              ),
              tabPanel('DaySummary',value = 'tab3',icon = icon('list-ol'),dataTableOutput('summary')),
              tabPanel('NetworkD3',value = 'network',icon = icon('line-chart'),simpleNetworkOutput('network'))
              
  )
))