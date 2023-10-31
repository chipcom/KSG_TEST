#include 'chip_mo.ch'
#include 'function.ch'

////* 23.12.18 ������⢮ ���, ����楢 � ���� � ��ப�
Function count_ymd(_mdate, _sys_date, /*@*/y, /*@*/m, /*@*/d)
  // _mdate    - ��� ��� ��।������ ������⢠ ���, ����楢 � ����
  // _sys_date - "��⥬���" ���
  Local ret_s := "", md := _mdate
  y := m := d := 0
  if !empty(_sys_date) .and. !empty(_mdate) .and. _sys_date > _mdate
    do while (md := addmonth(md,12)) <= _sys_date
      ++y
    enddo
    if y > 0 .and. correct_count_ym(_mdate,_sys_date)
      --y
    endif
    md := addmonth(_mdate,12*y)
    do while (md := addmonth(md,1)) <= _sys_date
      ++m
    enddo
    if m > 0 .and. correct_count_ym(_mdate,_sys_date,2)
      --m
    endif
    md := addmonth(_mdate,12*y+m)
    do while (md := md+1) <= _sys_date
      ++d
    enddo
    if !emptyall(y,m) .and. d > 0 // ⮫쪮 �� ��� ����஦�������
      --d
    endif
  endif
  if y > 0
    ret_s := lstr(y)+" "+s_let(y)+" "
  endif
  if m > 0
    ret_s += lstr(m)+" "+mes_cev(m)+" "
  endif
  if d > 0
    ret_s += lstr(d)+" "+dnej(d)
  endif
  return rtrim(ret_s)

////* 23.12.18 ��� ��⠥��� ���⨣訬 ��।��񭭮�� ������ �� � ���� ஦�����, � ��稭�� � ᫥����� ��⮪
Function correct_count_ym(_mdate,_sys_date,y_m)
  Local s1 := right(dtos(_mdate),4), s2 := right(dtos(_sys_date),4), fl := .f.
  DEFAULT y_m TO 1
  if s1 == s2 // �஢��塞 ࠢ���⢮ ��� � �����
    fl := .t.
  elseif s1 == "0229" .and. s2 == "0228" .and. !IsLeap(_sys_date) //_mdate - ��᮪��� ���, � _sys_date - ���
    fl := .t.
  elseif y_m == 2 .and. right(s1,2) == right(s2,2) // �஢��塞 ࠢ���⢮ ��� (��� ���-�� ���-�� ����楢)
    fl := .t.
  endif
  return fl

// �������� �� date1 (�������� date1-date2) � �������� _begin_date-_end_date
Function between_date(_begin_date,_end_date,date1,date2, impossiblyEmptyRange)
  // _begin_date - ��砫� ����⢨�
  // _end_date   - ����砭�� ����⢨�
  // date1 - �஢��塞�� ���
  // date2 - ���� ��� ��������� (�᫨ = NIL, � �஢��塞 ⮫쪮 �� date1)
  // impossiblyEmptyRange - �᫨ .t. ���⮩ �������� ��� �� �����⨬
  Local fl := .f., fl2

  // �஢�ਬ �� �������⨬���� ���⮣� ��������� ���
  if ! hb_isnil( impossiblyEmptyRange ) .and. impossiblyEmptyRange
    if empty(_begin_date) .and. empty(_end_date)
      return fl
    endif
  endif

  DEFAULT date1 TO sys_date  // �� 㬮�砭�� �஢��塞 �� ᥣ����譨� ������
  if empty(_begin_date)
    _begin_date := stod("19930101")  // �᫨ ��砫� ����⢨� = ����, � 01.01.1993
  endif
  // �஢�ઠ ���� date1 �� ��������� � ��������
  if (fl := (date1 >= _begin_date)) .and. !empty(_end_date)
    fl := (date1 <= _end_date)
  endif
  // �஢�ઠ ��������� date1-date2 �� ����祭�� � ����������
  if valtype(date2) == 'D'
    if (fl2 := (date2 >= _begin_date)) .and. !empty(_end_date)
      fl2 := (date2 <= _end_date)
    endif
    fl := (fl .or. fl2)
  endif
  return fl

// 04.11.21
// ������ ��䨪� �ࠢ�筮�� 䠩�� ��� ����
function prefixFileRefName(in_date)
  local valYear

  // �஢�ਬ �室�� ��ࠬ����
  if valtype(in_date) == 'D'
    valYear := year(in_date)
  elseif valtype(in_date) == 'N' .and. in_date >= 2018 .and. in_date <= WORK_YEAR
    valYear := in_date
  else
    valYear := WORK_YEAR
  endif

  return '_mo' + substr(str(valYear, 4, 0), 4, 1)
