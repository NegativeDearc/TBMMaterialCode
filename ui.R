library(shiny)
library(RODBC)

shinyUI(pageWithSidebar( 
  
  headerPanel (h1("当日排产备料代码汇总"),windowTitle = '备料代码汇总'),
  
  sidebarPanel(width =3 ,
               helpText('本程序由技术部提供',
                        br(),
                        '支持电话18260279625'
                        ),
               checkboxGroupInput("checkbox",
                                  choices = list('内面胶' = 'Innerliner Code',
                                                 '1号帘布' = '1#Ply Code',
                                                 '2号帘布' = '2#Ply Code',
                                                 '三角胶' = 'BF code',
                                                 '胎边' = 'Sidewall code',
                                                 '胎面' = 'Tread code',
                                                 '1层环带' = '1# Belt code',
                                                 '2层环带' = '2# Belt code'),
                                  label = '请选择项目(可多选)'
                                  ),
               actionButton("action", icon = icon('search'),label = "点击刷新,刷了也没用")
               ),
  
  mainPanel(
    tabsetPanel(
      id = 'dataset',type = 'tabs',
      tabPanel('白班', icon = icon("list-alt"),dataTableOutput(outputId = 'table1')),
      tabPanel('夜班',icon = icon("list-alt"),dataTableOutput(outputId = 'table_night')),
      tabPanel('白班汇总', icon = icon("list-alt"),dataTableOutput(outputId = 'table')),
      tabPanel('作者',icon = icon('user'),
               h5("作者: 技术部Sheldon",br(),
                  "Current Time:",as.POSIXct(Sys.time()),tz = "GMT",br(),
                  "如遇到程序bug或者建议点击发送邮件",
                  a(href="mailto:sxchen@coopertire.com&Subject=feedback","点这里"))),
      tabPanel('更新记录表',icon = icon('list-alt'),includeHTML('log.html'))
      ))
)
)