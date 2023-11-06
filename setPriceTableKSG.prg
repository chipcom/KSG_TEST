#include 'common.ch'
#include 'chip_mo.ch'
#include 'tableKSG.ch'
#include 'ksg_test.ch'

function setPriceTableKSG(aKSG, dBeg, dEnd)
  // aKSG - список КСГ
  // dBeg - дата начала случая
  // dEnd - дата окончания случая
  local row
  local lOpenLUSLC, lal, tmp_select := select()
  local fName, fname_add, sind1, sind2
  local fl_delete, fl_yes, nCena

  default dBeg to date()
  default dEnd to date()

  lal := 'luslc'
  lal := create_name_alias(lal, dEnd)
  lOpenLUSLC := (select(lal) != 0)
  if ! lOpenLUSLC
    fName := prefixFileRefName(Year(dEnd)) + 'uslc'  //substr(sbase, 2)
    fname_add := prefixFileRefName(Year(dEnd)) + 'uslu'  //substr(sbase, 2, 3) + 'u'
    sind1 := cur_dir + fName + sntx
    sind2 := cur_dir + fname_add + sntx
    R_Use(exe_dir + fName, {cur_dir + fName, cur_dir + fName_add}, lal)
  endif
  for each row in aKSG
    row[KSG_STOIM_KSG] := fcena_oms_new(row[KSG_SHIFR], .f., dEnd, @fl_delete, @fl_yes)
  next

  if ! lOpenLUSLC  // закрываем если открывали внутри функции
    (lal)->(dbCloseArea())
  endif
  select(tmp_select)

  return aKSG
