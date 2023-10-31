#include 'chip_mo.ch'
#include 'function.ch'

////* 23.12.18 количество лет, месяцев и дней в строке
Function count_ymd(_mdate, _sys_date, /*@*/y, /*@*/m, /*@*/d)
  // _mdate    - дата для определения количества лет, месяцев и дней
  // _sys_date - "системная" дата
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
    if !emptyall(y,m) .and. d > 0 // только не для новорожденного
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

////* 23.12.18 лицо считается достигшим определённого возраста не в день рождения, а начиная со следующих суток
Function correct_count_ym(_mdate,_sys_date,y_m)
  Local s1 := right(dtos(_mdate),4), s2 := right(dtos(_sys_date),4), fl := .f.
  DEFAULT y_m TO 1
  if s1 == s2 // проверяем равенство дня и месяца
    fl := .t.
  elseif s1 == "0229" .and. s2 == "0228" .and. !IsLeap(_sys_date) //_mdate - високосный год, а _sys_date - нет
    fl := .t.
  elseif y_m == 2 .and. right(s1,2) == right(s2,2) // проверяем равенство дня (для опр-ия кол-ва месяцев)
    fl := .t.
  endif
  return fl

// попадает ли date1 (диапазон date1-date2) в диапазон _begin_date-_end_date
Function between_date(_begin_date,_end_date,date1,date2, impossiblyEmptyRange)
  // _begin_date - начало действия
  // _end_date   - окончание действия
  // date1 - проверяемая дата
  // date2 - вторая дата диапазона (если = NIL, то проверяем только по date1)
  // impossiblyEmptyRange - если .t. пустой диапазон дат не допустим
  Local fl := .f., fl2

  // проверим на недопустимость пустого диапазона дат
  if ! hb_isnil( impossiblyEmptyRange ) .and. impossiblyEmptyRange
    if empty(_begin_date) .and. empty(_end_date)
      return fl
    endif
  endif

  DEFAULT date1 TO sys_date  // по умолчанию проверяем на сегодняшний момент
  if empty(_begin_date)
    _begin_date := stod("19930101")  // если начало действия = пусто, то 01.01.1993
  endif
  // проверка даты date1 на попадание в диапазон
  if (fl := (date1 >= _begin_date)) .and. !empty(_end_date)
    fl := (date1 <= _end_date)
  endif
  // проверка диапазона date1-date2 на пересечение с диапазоном
  if valtype(date2) == 'D'
    if (fl2 := (date2 >= _begin_date)) .and. !empty(_end_date)
      fl2 := (date2 <= _end_date)
    endif
    fl := (fl .or. fl2)
  endif
  return fl

// 04.11.21
// вернуть префикс справочного файла для года
function prefixFileRefName(in_date)
  local valYear

  // проверим входные параметры
  if valtype(in_date) == 'D'
    valYear := year(in_date)
  elseif valtype(in_date) == 'N' .and. in_date >= 2018 .and. in_date <= WORK_YEAR
    valYear := in_date
  else
    valYear := WORK_YEAR
  endif

  return '_mo' + substr(str(valYear, 4, 0), 4, 1)
