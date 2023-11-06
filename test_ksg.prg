#include 'common.ch'
#include 'chip_mo.ch'
#include 'tableKSG.ch'
#include 'ksg_test.ch'

procedure main( ... )

  local fedUslugi, mainDiag, aDiagAdd, aDiagOsl, aAdCrit, cFr
  local aKSG  // α―¨αÿª ‘ƒ

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

  public Err_version := '’¥αβ ‘ƒ'
  public fio_polzovat := ''
  public sdbf := '.dbf', sdbt := '.dbt', sntx := '.ntx'
  public exe_dir := DICT_DIR
  public cur_dir := WORK_DIR

  mainDiag := '' //'L10.4'  // 'n82.9'
  fedUslugi := {'A16.12.006.001', 'A16.12.008.003'} // {'A06.04.018'}
  aDiagAdd := {}
  aDiagOsl := {}
  aAdCrit := {'derm1', 'lgh3'}
  cFr := ''

  aKSG := createTableKSG( ctod('01/08/2003'), 2, ctod('01/08/2022'), ctod('10/08/2022'), USL_OK_HOSPITAL, mainDiag, aDiagAdd, aDiagOsl, fedUslugi, aAdCrit, cFr )
  if ! empty(aKSG)
    setPriceTableKSG(aKSG, ctod('01/08/2022'), ctod('10/08/2022'))
  endif

  altd()

  return

