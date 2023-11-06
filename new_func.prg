#include 'common.ch'
#include 'chip_mo.ch'
#include 'tableKSG.ch'
#include 'ksg_test.ch'

// 24.11.21
Function fcena_oms_new(cKSG, lVzReb, dDate, /*@*/fl_delete, /*@*/fl_yes)
  // cKSG - ��� ���
  // lVzReb - 䫠� �����/ॡ���� ( - �����, - ॡ����)
  // dDate - ��� �������� ��㣨
  // fl_delete - 
  // fl_yes - 
  Local nCena, tmp_select := select(), lvr, lal
  // local nu, s := glob_mo[_MO_KOD_TFOMS], i

  cKSG := lower(padr(cKSG, 10))
  if valtype(dDate) == 'D'
    dDate := dDate
  endif
  // if !empty(glob_podr) .and. year(dDate) == 2017
  //   s := padr(glob_podr, 6) // �����塞 �� ��� ���� ���ࠧ�������
  // endif
  lvr := iif(lVzReb, 0, 1)
  nCena := 0
  // nu := get2uroven(cKSG, get_uroven(dDate))
  fl_delete := .t.
  fl_yes := .f.
  lal := 'luslc'
  lal := create_name_alias(lal, dDate)
altd()
  dbselectarea(lal)
  set order to 1
  // find (cKSG + str(lvr, 1) + str(glob_otd_dep, 3)) // ᭠砫� �饬 業� ��� �����⭮�� �⤥�����
  // do while cKSG == &lal.->shifr .and. &lal.->VZROS_REB == lvr .and. &lal.->depart == glob_otd_dep .and. !eof()
  //   fl_yes := .t.
  //   if between_date(&lal.->datebeg, &lal.->dateend, dDate) // ���� 業� �� ��� ����砭�� ��祭��
  //     fl_delete := .f.
  //     nCena := &lal.->CENA
  //     exit
  //   endif
  //   skip
  // enddo
  // if !fl_yes .and. fl_delete // �᫨ �� ��諨
    find (cKSG + str(lvr, 1) + str(0, 3)) // � �饬 業� ��� depart = 0
    do while cKSG == &lal.->shifr .and. &lal.->VZROS_REB == lvr .and. &lal.->depart == 0 .and. !eof()
      fl_yes := .t.
      if between_date(&lal.->datebeg, &lal.->dateend, dDate) // ���� 業� �� ��� ����砭�� ��祭��
        fl_delete := .f.
        nCena := &lal.->CENA
        exit
      endif
      skip
    enddo
  // endif
  select (tmp_select)
  return nCena
