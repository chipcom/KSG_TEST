#include 'common.ch'
#include 'chip_mo.ch'

procedure main( ... )

  local fedUslugi, mainDiag, aDiagAdd, aDiagOsl, aAdCrit, cFr

  REQUEST HB_CODEPAGE_RU866
  HB_CDPSELECT('RU866')
  REQUEST HB_LANG_RU866
  HB_LANGSELECT('RU866')

  //SET(_SET_EVENTMASK,INKEY_KEYBOARD)
  SET SCOREBOARD OFF
  SET EXACT ON
  SET DATE GERMAN
  SET WRAP ON
  SET CENTURY ON
  SET EXCLUSIVE ON
  SET DELETED ON

  public cDataCScr, help_code
  public cColorStMsg, cColorSt1Msg, cColorSt2Msg, cColorWait
  
  cDataCScr   := 'W+/B,B/BG'              // 1
  help_code := 0
  color0 := 'N/BG, W+/N'
  cColorStMsg := 'W+/R,,,,B/W'                  //    Stat_msg
  cColorSt1Msg:= 'W+/R,,,,B/W'                //    Stat_msg
  cColorSt2Msg:= 'GR+/R,,,,B/W'                //    Stat_msg
  cColorWait  := 'W+/R*,,,,B/W'                 //    †¤¨β¥

  public Err_version := '’¥αβ ‘ƒ ÿβ '
  public fio_polzovat := ''

  
  // R_Use('d:\_mo\chip\exe\_mo3k006', {'d:\_mo\chip\work\_mo3k006', 'd:\_mo\chip\work\_mo3k006_', 'd:\_mo\chip\work\_mo3k006AD'}, 'K006')
  // R_Use('d:\_mo\chip\exe\_mo3k006', , 'K006')

  mainDiag := 'i83.9'  // 'n82.9'
  fedUslugi := {'A16.12.006.001'} // {'A06.04.018'}
  aDiagAdd := {}
  aDiagOsl := {}
  aAdCrit := {}
  cFr := ''

  defenitionKSG( ctod('01/08/2023'), 2, , , USL_OK_HOSPITAL, mainDiag, aDiagAdd, aDiagOsl, fedUslugi, aAdCrit, cFr )

  // k006->(dbCloseArea())
  return

