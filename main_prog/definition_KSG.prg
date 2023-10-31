#include 'inkey.ch'
#include 'function.ch'
#include 'edit_spr.ch'
#include 'chip_mo.ch'
 

** 05.03.23 определение КСГ по остальным введённым полям ввода - 2019-22 год
Function definition_KSG(par, k_data2, lDoubleSluch)
  // файлы 'human', 'human_' и 'human_2' открыты и стоят на нужной записи
  //       'human' открыт для записи суммы случая
  // выполнено use_base('human_u', 'HU') - для записи
  // выполнено use_base('mo_hu', 'MOHU') - для записи
  Static ver_year := 0 // последний проверяемый год
  Static ad_ksg_3, ad_ksg_4
  Static sp0, sp1, sp6, sp15
  Static a_iskl_1 := {; // исключение из правил №1
    {'st02.010', 'st02.008'}, ;
    {'st02.011', 'st02.008'}, ;
    {'st02.010', 'st02.009'}, ;
    {'st14.001', 'st04.002'}, ;
    {'st14.004', 'st04.002'}, ;
    {'st21.001', 'st21.007'}, ;
    {'st34.002', 'st34.001'}, ;
    {'st34.002', 'st26.001'}, ;
    {'st34.006', 'st30.003'}, ;
    {'st09.001', 'st30.005'}, ;
    {'st31.002', 'st31.017'}, ;
    {'st37.001', ''}, ;
    {'st37.002', ''}, ;
    {'st37.003', ''}, ;
    {'st37.004', ''}, ;
    {'st37.005', ''}, ;
    {'st37.006', ''}, ;
    {'st37.007', ''}, ;
    {'st37.008', ''}, ;
    {'st37.009', ''}, ;
    {'st37.010', ''}, ;
    {'st37.011', ''}, ;
    {'st37.012', ''}, ;
    {'st37.013', ''}, ;
    {'st37.014', ''}, ;
    {'st37.015', ''}, ;
    {'st37.016', ''}, ;
    {'st37.017', ''}, ;
    {'st37.018', ''}, ;
    {'ds37.001', ''}, ;
    {'ds37.002', ''}, ;
    {'ds37.003', ''}, ;
    {'ds37.004', ''}, ;
    {'ds37.005', ''}, ;
    {'ds37.006', ''}, ;
    {'ds37.007', ''}, ;
    {'ds37.008', ''}, ;
    {'ds37.009', ''}, ;
    {'ds37.010', ''}, ;
    {'ds37.011', ''}, ;
    {'ds37.012', ''};
   }

  Local mdiagnoz, aHirKSG := {}, aTerKSG := {}, fl_cena := .f., lvmp, lvidvmp := 0, lstentvmp := 0, ;
        i, j, k, c, s, ar, ar1, fl, im, lshifr, ln_data, lk_data, lvr, ldni, ldate_r, lpol, lprofil_k, ;
        lfio, cenaTer := 0, cenaHir := 0, ksgHir, ars := {}, arerr := {}, ;
        lksg := '', lcena := 0, osn_diag3, lprofil, ldnej := 0, y := 0, m := 0, d := 0, ;
        osn_diag := space(6), sop_diag := {}, osl_diag := {}, tmp, lrslt, akslp, akiro, ;
        lad_cr := '', lad_cr1 := '', lis_err := 0, akslp2, lpar_org := 0, lyear, ;
        kol_ter := 0, kol_hir := 0, lkoef, fl_reabil, lkiro := 0, lkslp := '', lbartell := '', ;
        lusl, susl, s_dializ := 0, ahu := {}, amohu := {}, ;
        date_usl := stod('20210101') // stod('20200101')

  local iKSLP, newKSLP := '', tmSel
  local humKSLP := ''
  local vkiro := 0

  DEFAULT par TO 1, sp0 TO '', sp1 TO space(1), sp6 TO space(6), sp15 TO space(20)
  default lDoubleSluch to .f.
  Private pole

  if par == 1
    uch->(dbGoto(human->LPU))
    otd->(dbGoto(human->OTD))
    if (lvmp := human_2->VMP) == 1
      lvidvmp := human_2->METVMP
    endif
    lad_cr  := alltrim(human_2->pc3)
    lfio    := alltrim(human->fio)
    ln_data := human->n_data
    if valtype(k_data2) == 'D'
      lk_data := k_data2
    else
      lk_data := human->k_data
    endif
    lusl    := human_->USL_OK
    ldate_r := iif(human_->NOVOR > 0, human_->date_r2, human->date_r)
    lpol    := iif(human_->NOVOR > 0, human_->pol2,    human->pol)
    lvr     := iif(human->VZROS_REB==0, 0, 1) // 0-взрослый, 1-ребенок
    lprofil := human_->profil
    lprofil_k := human_2->profil_k
    lrslt   := human_->rslt_new
    // массив диагнозов (минимум два)
    mdiagnoz := diag_to_array(,,,,.t.)
    if len(mdiagnoz) > 0
      osn_diag := mdiagnoz[1]
      if len(mdiagnoz) > 1
        sop_diag := aclone(mdiagnoz)
        Del_Array(sop_diag,1) // начиная со 2-го - сопутствующие диагнозы
      endif
    endif
    if !empty(human_2->OSL1)
      aadd(osl_diag,human_2->OSL1)
    endif
    if !empty(human_2->OSL2)
      aadd(osl_diag,human_2->OSL2)
    endif
    if !empty(human_2->OSL3)
      aadd(osl_diag,human_2->OSL3)
    endif

    if lusl < 3 .and. lVMP == 0 .and. f_is_oncology(1) == 2 .and. empty(lad_cr)
      if select('ONKSL') == 0
        G_Use(dir_server + 'mo_onksl', dir_server + 'mo_onksl', 'ONKSL') // Сведения о случае лечения онкологического заболевания
      endif
      select ONKSL
      find (str(human->kod,7))
      lad_cr := alltrim(onksl->crit)
      if lad_cr == 'нет'
        lad_cr := ''
      endif
      lad_cr1 := alltrim(onksl->crit2)
      lis_err := onksl->is_err
    endif
  else // из режима импорта случаев
    if (lvmp := iif(empty(ihuman->VID_HMP), 0, 1)) == 1
      lvidvmp := ihuman->METOD_HMP
    endif
    lad_cr  := alltrim(ihuman->ad_cr)
    if lad_cr == 'нет'
      lad_cr := ''
    endif
    lad_cr1 := alltrim(ihuman->ad_cr2)
    lis_err := ihuman->is_err
    lusl    := ihuman->USL_OK
    lfio    := alltrim(ihuman->fio)
    ln_data := ihuman->date_1
    if valtype(k_data2) == 'D'
      lk_data := k_data2
    else
      lk_data := ihuman->date_2
    endif
    ldate_r := iif(ihuman->NOVOR > 0, ihuman->reb_dr,  ihuman->dr)
    lpol    := iif(ihuman->NOVOR > 0, ihuman->reb_pol, ihuman->w)
    lpol    := iif(lpol == 1, 'М', 'Ж')
    lvr     := iif(m1VZROS_REB==0, 0, 1) // 0-взрослый, 1-ребенок
    lprofil := ihuman->profil
    lprofil_k := ihuman->profil_k
    lrslt   := ihuman->rslt
    osn_diag := padr(ihuman->DS1, 6)
    if !empty(ihuman->DS2)
      aadd(sop_diag, padr(ihuman->DS2, 6))
    endif
    if !empty(ihuman->DS2_2)
      aadd(sop_diag, padr(ihuman->DS2_2, 6))
    endif
    if !empty(ihuman->DS2_3)
      aadd(sop_diag, padr(ihuman->DS2_3, 6))
    endif
    if !empty(ihuman->DS2_4)
      aadd(sop_diag, padr(ihuman->DS2_4, 6))
    endif
    if !empty(ihuman->DS2_5)
      aadd(sop_diag, padr(ihuman->DS2_5, 6))
    endif
    if !empty(ihuman->DS2_6)
      aadd(sop_diag, padr(ihuman->DS2_6, 6))
    endif
    if !empty(ihuman->DS2_7)
      aadd(sop_diag, padr(ihuman->DS2_7, 6))
    endif
    mdiagnoz := aclone(sop_diag)
    Ins_Array(mdiagnoz, 1, osn_diag)
    if !empty(ihuman->DS3)
      aadd(osl_diag, padr(ihuman->DS3, 6))
    endif
    if !empty(ihuman->DS3_2)
      aadd(osl_diag, padr(ihuman->DS3_2, 6))
    endif
    if !empty(ihuman->DS3_3)
      aadd(osl_diag, padr(ihuman->DS3_3, 6))
    endif
  endif

  //
  lyear := year(lk_data)
  if eq_any(lad_cr, '60', '61')
    lbartell := lad_cr
    lad_cr := ''
  endif
  ldni := ln_data - ldate_r // для ребёнка возраст в днях
  count_ymd(ldate_r, ln_data, @y, @m, @d)
  date_usl := lk_data //!!!!!!!!!!!!раскомментировать после теста!!!!!!!!!!!!!!!
  if lusl == 1 // стационар
    if (ldnej := lk_data - ln_data) == 0
      ldnej := 1
    endif
  endif
  aadd(ars, lfio + ' ' + date_8(ln_data) + '-' + date_8(lk_data) + ' (' + lstr(ldnej) + 'дн.)')
  s := iif(lVMP==1, 'ВМП ', ' ')
  if par == 1
    s += alltrim(uch->name) + '/' + alltrim(otd->name) + '/'
  endif
  s += 'профиль "' + inieditspr(A__MENUVERT, getV002(), lprofil) + '"'
  aadd(ars, s)
  aadd(ars, ' д.р.' + full_date(ldate_r) + iif(lvr==0, '(взр.', '(реб.') + '), ' + iif(lpol == 'М', 'муж.', 'жен.') +;
           ', осн.диаг.' + osn_diag +;
           iif(empty(sop_diag), '', ', соп.диаг.' + charrem(' ', print_array(sop_diag))) +;
           iif(empty(osl_diag), '', ', диаг.осл.' + charrem(' ', print_array(osl_diag))))
  if empty(osn_diag)
    aadd(arerr, ' не введён основной диагноз')
    return {ars, arerr, lksg, lcena, {}, {}}
  endif
  if f_put_glob_podr(lusl, date_usl, arerr) // если не заполнен код подразделения
    return {ars, arerr, lksg, lcena, {}, {}}
  endif
  if lvmp > 0
    if lvidvmp == 0
      aadd(arerr, ' не введён метод ВМП')
    elseif (ascan(arr_12_VMP, lvidvmp) == 0 .and. year(lk_data) < 2021)
      aadd(arerr, ' для метода ВМП ' + lstr(lvidvmp) + ' нет услуги ТФОМС')
    else
      lksg := getServiceForVMP(lvidvmp, lk_data, human_2->VIDVMP, human_2->METVMP, human_2->PN5, human->KOD_DIAG)
      aadd(ars, ' для ' + lstr(lvidvmp) + ' метода ВМП введена услуга ' + lksg)
      lcena := ret_cena_KSG(lksg, lvr, date_usl)
      if lcena > 0
        aadd(ars, ' РЕЗУЛЬТАТ: выбрана услуга=' + lksg + ' с ценой ' + lstr(lcena, 11, 0))
      else
        aadd(arerr, ' для Вашей МО в справочнике ТФОМС не найдена услуга: ' + lksg)
      endif
    endif
    return {ars, arerr, alltrim(lksg), lcena, {}, {}}
  endif
  lal := create_name_alias('LUSL', lyear)
  lalf := create_name_alias('LUSLF', lyear)
  if select('LUSLF') == 0
    use_base('LUSLF')
  endif

  // составляем массив услуг и массив манипуляций
  if par == 1
    select HU
    find (str(human->kod, 7))
    do while hu->kod == human->kod .and. !eof()
      usl->(dbGoto(hu->u_kod))
      if empty(lshifr := opr_shifr_TFOMS(usl->shifr1, usl->kod, date_usl))
        lshifr := usl->shifr
      endif
      lshifr := alltrim(lshifr)
      if left(lshifr, 5) == '60.3.'
        s_dializ += hu->stoim_1
      endif
      if ascan(ahu, lshifr) == 0
        aadd(ahu, lshifr)
      endif
      if lusl == 2 .and. left(lshifr, 5)=='55.1.'
        ldnej += hu->kol_1
      endif
      select HU
      skip
    enddo
    if select('MOSU') == 0
      R_Use(dir_server + 'mo_su', , 'MOSU')
    endif
    select MOHU
    find (str(human->kod, 7))
    do while mohu->kod == human->kod .and. !eof()
      if mosu->(recno()) != mohu->u_kod
        mosu->(dbGoto(mohu->u_kod))
      endif
      if ascan(amohu, mosu->shifr1) == 0
        aadd(amohu, mosu->shifr1)
      endif
      dbSelectArea(lalf)
      find (padr(mosu->shifr1, 20))
      if found() .and. !empty(&lalf.->par_org)
        lpar_org += len(List2Arr(mohu->zf))
      endif
      select MOHU
      skip
    enddo
  else
    select IHU
    find (str(ihuman->kod, 10))
    do while ihu->kod == ihuman->kod .and. !eof()
      if eq_any(left(ihu->CODE_USL, 1), 'A', 'B')
        if ascan(amohu, ihu->CODE_USL) == 0
          aadd(amohu, ihu->CODE_USL)
        endif
        dbSelectArea(lalf)
        find (padr(ihu->CODE_USL, 20))
        if found() .and. !empty(&lalf.->par_org)
          lpar_org += len(List2Arr(ihu->par_org))
        endif
      else
        if ascan(ahu, alltrim(ihu->CODE_USL)) == 0
          aadd(ahu, alltrim(ihu->CODE_USL))
        endif
        if left(ihu->CODE_USL, 5) == '60.3.'
          s_dializ += ihu->SUMV_USL
        endif
        if lusl == 2 .and. left(ihu->CODE_USL, 5)=='55.1.'
          ldnej += ihu->KOL_USL
        endif
      endif
      select IHU
      skip
    enddo
  endif

  //
  if lvr == 0 //
    lage := '6'
    s := 'взр.'
  else
    lage := '5'
    s := 'дети'
    fl := .t.
    if ldni <= 28
      lage += '1' // дети до 28 дней
      s := '0-28дн.'
      fl := .f.
    elseif ldni <= 90
      lage += '2' // дети до 90 дней
      s := '29-90дн.'
      fl := .f.
    elseif y < 1 // до 1 года
      lage += '3' // дети от 91 дня до 1 года
      s := '91день-1год'
      fl := .f.
    endif
    if y <= 2 // до 2 лет включительно
      lage += '4' // дети до 2 лет
      if fl
        s := 'до2лет включ.'
      endif
    endif
  endif
  ars[1] := lfio + ' ' + date_8(ln_data) + '-' + date_8(lk_data) + ' (' + lstr(ldnej) + 'дн.)'
  ars[3] := ' д.р.' + full_date(ldate_r) + '(' +s+ '), ' + iif(lpol == 'М', 'муж.', 'жен.') +;
            ', осн.диаг.' + osn_diag +;
            iif(empty(sop_diag), '', ', соп.диаг.' + charrem(' ',print_array(sop_diag))) +;
            iif(empty(osl_diag), '', ', диаг.осл.' + charrem(' ',print_array(osl_diag)))
  lsex := iif(lpol == 'М', '1', '2')

  llos := {} //''
  if ldnej < 4
    aadd(llos, '1') //llos += '1'
  elseif between(ldnej, 4, 10)
    aadd(llos, '11')
  elseif between(ldnej, 11, 20)
    aadd(llos, '12')
  elseif between(ldnej, 21, 30)
    aadd(llos, '13')
  endif
  /*
  0 - КИРО не применяется
  1 - длительность случая 3 койко-дня (дней лечения) и менее и пациенту выполнена хирургическая операция
      либо другое вмешательство, являющиеся классификационным критерием отнесения данного случая лечения
      к конкретной КСГ вне зависимости от сочетания с результатами обращения за медицинской помощью
  2 - длительность случая 3 койко-дня (дней лечения) и менее, но хирургическое лечение либо другое вмешательство,
      определяющее отнесение к КСГ не проводилось и критерием отнесения в случае является код диагноза по МКБ 10
      вне зависимости от сочетания с результатами обращения за медицинской помощью;
  3 - длительность случая 4 койко-дня (дней лечения) и более и пациенту выполнена хирургическая операция
      либо другое вмешательство, являющиеся классификационным критерием отнесения данного случая лечения
      к конкретной КСГ в сочетании с результатами обращения за медицинской помощью
      (Классификатор V009) 102, 105, 107, 110, 202, 205, 207
  4 - длительность случая 4 койко-дня (дней лечения) и более, но хирургическое лечение либо другое вмешательство,
      определяющее отнесение к КСГ не проводилось, в сочетании с результатами обращения за медицинской помощью
      (Классификатор V009) 102, 105, 107, 110, 202, 205, 207
  5 - случаи с несоблюдением режима введения лекарственного препарата (дней введения в схеме) согласно инструкции
      к препарату при длительности случая 3 койко-дня (дня лечения) и менее вне зависимости от результата обращения
      за медицинской помощью
  6 - случаи с несоблюдением режима введения лекарственного препарата (дней введения в схеме) согласно инструкции
      к препарату при длительности случая 4 койко-дня (дня лечения) и более в сочетании с результатами обращения
      за медицинской помощью (Классификатор V009) 102, 105, 107, 110, 202, 205, 207
  */
  //aadd(ars, '   ║age=' +lage+ ' sex=' +lsex+ ' los=' +print_array(llos))

  nfile := prefixFileRefName(lyear) + 'k006'
  if select('K006') == 0
    R_Use(exe_dir + nfile, {cur_dir + nfile, cur_dir + nfile + '_', cur_dir + nfile + 'AD'}, 'K006')
  else
    if ver_year == lyear // проверяем: если тот же год, что только что проверяли
      // ничего не меняем
    else // иначе переоткрываем данный файл с необходимым годом и тем же алиасом
      k006->(dbCloseArea())
      R_Use(exe_dir + nfile, {cur_dir + nfile, cur_dir + nfile + '_', cur_dir + nfile + 'AD'}, 'K006')
    endif
  endif
  ver_year := lyear
  fl_reabil := (ascan(ahu, '1.11.2') > 0 .or. ascan(ahu, '55.1.4') > 0)
  susl := iif(lusl == 1, 'st', 'ds')

  // собираем КСГ по осн.диагнозу (терапевтические и комбинированные)
  ar := {}
  tmp := {}
  select K006

  if lprofil == 137   // ЭКО
    set order to 3
    K006->(dbGoTop())
    K006->(dbseek(lower(lad_cr)))
    do while lower(alltrim(K006->AD_CR)) == lower(alltrim(lad_cr)) .and. !('K006')->(Eof())

      lkoef := k006->kz
      dbSelectArea(lal)
      find (padr(k006->shifr, 10))
      fl := lkoef > 0 .and. between_date(&lal.->DATEBEG, &lal.->DATEEND, date_usl)
      if fl
        fl := between_date(k006->DATEBEG, k006->DATEEND, date_usl)
      endif
      j := 0
      j++
      j++
      if fl
        aadd(ar, {k006->shifr, ; //  1
                 0, ;           //  2
                 lkoef, ;       //  3
                 &lal.->kiros, ; //  4
                 osn_diag, ;    //  5
                k006->sy, ;    //  6
                k006->age, ;   //  7
                k006->sex, ;   //  8
                k006->los, ;   //  9
                k006->ad_cr, ; // 10
                '', ;        // 11
                '', ;        // 12
                j, ;           // 13
                &lal.->kslps, ; // 14
                k006->ad_cr1}) // 15
      endif

      K006->(dbSkip())
    enddo
  else
    set order to 1
    find (susl+padr(osn_diag, 6))
    do while left(k006->shifr, 2) == susl .and. k006->ds == padr(osn_diag, 6) .and. !eof()
      lkoef := k006->kz
      dbSelectArea(lal)
      find (padr(k006->shifr, 10))
      fl := lkoef > 0 .and. between_date(&lal.->DATEBEG, &lal.->DATEEND, date_usl)
      if fl
        fl := between_date(k006->DATEBEG, k006->DATEEND, date_usl)
      endif
      if fl
        sds1 := iif(empty(k006->ds1), sp0, alltrim(k006->ds1) + sp6) // соп.диагноз
        sds2 := iif(empty(k006->ds2), sp0, alltrim(k006->ds2) + sp6) // диагн.осложнения
      endif
      j := 0

      // что-то здесь не так
      if fl .and. !empty(k006->sy)
        if (i := ascan(amohu, k006->sy)) > 0
          j += 10
        else
          fl := .f.
        endif
      endif
      // конец что-то здесь не так
      
      if fl .and. !empty(k006->age)
        if (fl := (k006->age $ lage))
          if k006->age == '1'
            j += 5
          elseif k006->age == '2'
            j += 4
          elseif k006->age == '3'
            j += 3
          elseif k006->age == '4'
            j += 2
          else
            j ++
          endif
        endif
      endif
      if fl .and. !empty(k006->sex)
        fl := (k006->sex == lsex)
        if fl
          j++
        endif
      endif
      if fl .and. !empty(k006->los)
        fl := ascan(llos, alltrim(k006->los)) > 0  // (k006->los $ llos)
        if fl
          j++
        endif
      endif

      if fl
        if empty(lad_cr) // в случае нет доп.критерия
          if !empty(k006->ad_cr) // а в справочнике есть доп.критерий
            fl := .f.
          endif
        else // в случае есть доп.критерий
          if empty(k006->ad_cr) // а в справочнике нет доп.критерия
            fl := .f.
          else                  // а в справочнике есть доп.критерий
            fl := (alltrim(lad_cr) == alltrim(k006->ad_cr))
            if fl
              j++
            endif
          endif
        endif
      endif
      if fl
        if empty(lad_cr1) // в случае нет доп.критерия2
          if !empty(k006->ad_cr1) // а в справочнике есть доп.критерий2
            fl := .f.
          endif
        else // в случае есть доп.критерий2
          if empty(k006->ad_cr1) // а в справочнике нет доп.критерия2
            fl := .f.
          else                  // а в справочнике есть доп.критерий2
            fl := (lad_cr1 == alltrim(k006->ad_cr1))
            if fl
              j++
            endif
          endif
        endif
      endif
      //
      if fl .and. !empty(sds1)
        fl := .f.
        for i := 1 to len(sop_diag)
          if alltrim(sop_diag[i]) $ sds1
            fl := .t.
            exit
          endif
        next
        if fl
          j++
        endif
      endif
      if fl .and. !empty(sds2)
        fl := .f.
        for i := 1 to len(osl_diag)
          if alltrim(osl_diag[i]) $ sds2
            fl := .t.
            exit
          endif
        next
        if fl
          j++
        endif
      endif
      //
      if fl
        if !empty(k006->sy) .and. (i := ascan(amohu, k006->sy)) > 0
          aadd(tmp, i)
        endif
        aadd(ar, {k006->shifr, ; //  1
                 0, ;           //  2
                 lkoef, ;       //  3
                 &lal.->kiros, ; //  4
                 osn_diag, ;    //  5
                k006->sy, ;    //  6
                k006->age, ;   //  7
                k006->sex, ;   //  8
                k006->los, ;   //  9
                k006->ad_cr, ; // 10
                sds1, ;        // 11
                sds2, ;        // 12
                j, ;           // 13
                &lal.->kslps, ; // 14
                k006->ad_cr1}) // 15
      endif
      select K006
      skip
    enddo
  endif
  ar1 := {}
  if lusl == 2 .and. !empty(lad_cr) .and. lad_cr == 'mgi'
    select K006
    Locate for k006->ad_cr == padr('mgi', 20)
    if found() // <CODE>ds19.033</CODE>
      lkoef := k006->kz
      dbSelectArea(lal)
      find (padr(k006->shifr, 10))
      fl := lkoef > 0 .and. between_date(&lal.->DATEBEG, &lal.->DATEEND, date_usl)
      if fl
        fl := between_date(k006->DATEBEG, k006->DATEEND, date_usl)
      endif
      if fl
        sds1 := iif(empty(k006->ds1), sp0, alltrim(k006->ds1) + sp6) // соп.диагноз
        sds2 := iif(empty(k006->ds2), sp0, alltrim(k006->ds2) + sp6) // диагн.осложнения
        j := 1
        ar := {}
        aadd(ar1, {k006->shifr, ; //  1
                  0, ;           //  2
                  lkoef, ;       //  3
                  &lal.->kiros, ; //  4
                  k006->ds, ;    //  5
                  lshifr, ;      //  6
                  k006->age, ;   //  7
                  k006->sex, ;   //  8
                  k006->los, ;   //  9
                  k006->ad_cr, ; // 10
                  sds1, ;        // 11
                  sds2, ;        // 12
                  j, ;           // 13
                  &lal.->kslps, ; // 14
                  k006->ad_cr1}) // 15
      endif
    endif
  endif
  if len(ar) > 0
    for i := 1 to len(tmp)
      im := tmp[i]
      amohu[im] := '' // очистить, чтобы не включать в хирургическую КСГ
    next
    for i := 1 to len(ar)
      ar[i, 2] := ret_cena_KSG(ar[i, 1], lvr, date_usl)
      if ar[i, 2] > 0
        fl_cena := .t.
      endif
    next
    aTerKSG := aclone(ar)
    if len(aTerKSG) > 1
      asort(aTerKSG, , , {|x, y| iif(x[13] == y[13], x[3] > y[3], x[13] > y[13])})
    endif
    /*aadd(ars, '   ║КСГ: ' +print_array(aTerKSG[1]))
    for j := 2 to len(aTerKSG)
      aadd(ars, '   ║     ' +print_array(aTerKSG[j]))
    next*/
    if (kol_ter := f_put_debug_KSG(0, aTerKSG, ars)) > 1
      aadd(ars, ' └─> выбираем КСГ=' + rtrim(aTerKSG[1, 1]) + ' [КЗ=' + lstr(aTerKSG[1, 3]) + ']')
    endif
  endif
  // собираем КСГ по манипуляциям (хирургические и комбинированные)
  ar := ar1
  for im := 1 to len(amohu)
    if !empty(lshifr := alltrim(amohu[im]))
      _a1 := {}
      select K006
      set order to 2
      find (susl+padr(lshifr, 20))
      do while left(k006->shifr, 2) == susl .and. k006->sy == padr(lshifr, 20) .and. !eof()
        lkoef := k006->kz
        dbSelectArea(lal)
        find (padr(k006->shifr, 10))
        fl := lkoef > 0 .and. between_date(&lal.->DATEBEG, &lal.->DATEEND, date_usl)
        if fl
          fl := between_date(k006->DATEBEG, k006->DATEEND, date_usl)
        endif
        if fl
          sds1 := iif(empty(k006->ds1), sp0, alltrim(k006->ds1) + sp6) // соп.диагноз
          sds2 := iif(empty(k006->ds2), sp0, alltrim(k006->ds2) + sp6) // диагн.осложнения
        endif
        j := 0
        if fl .and. !empty(k006->ds)
          fl := (k006->ds == osn_diag)
          if fl
            j += 10
          endif
        endif
        if fl .and. !empty(k006->age)
          if (fl := (k006->age $ lage))
            if k006->age == '1'
              j += 5
            elseif k006->age == '2'
              j += 4
            elseif k006->age == '3'
              j += 3
            elseif k006->age == '4'
              j += 2
            else
              j++
            endif
          endif
        endif
        if fl .and. !empty(k006->sex)
          fl := (k006->sex == lsex)
          if fl
            j++
          endif
        endif
        if fl .and. !empty(k006->los)
          fl := ascan(llos, alltrim(k006->los)) > 0  // (k006->los $ llos)
          if fl
            j++
          endif
        endif
        if fl .and. !empty(k006->ad_cr)  // в справочнике есть доп.критерий
          fl := .f.
          if !empty(lad_cr)        // в случае есть доп.критерий
            fl := (lad_cr == alltrim(k006->ad_cr))
            if fl
              j++
            endif
          endif
        endif
        if fl .and. !empty(k006->ad_cr1)  // в справочнике есть доп.критерий2
          fl := .f.
          if !empty(lad_cr1)        // в случае есть доп.критерий2
            fl := (lad_cr1 == alltrim(k006->ad_cr1))
            if fl
              j++
            endif
          endif
        endif
        if fl .and. !empty(sds1)
          fl := .f.
          for i := 1 to len(sop_diag)
            if alltrim(sop_diag[i]) $ sds1
              fl := .t.
              exit
            endif
          next
          if fl
            j++
          endif
        endif
        if fl .and. !empty(sds2)
          fl := .f.
          for i := 1 to len(osl_diag)
            if alltrim(osl_diag[i]) $ sds2
              fl := .t.
              exit
            endif
          next
          if fl
            j++
          endif
        endif
        if fl
          aadd(_a1, {k006->shifr, ; //  1
                    0, ;           //  2
                    lkoef, ;       //  3
                    &lal.->kiros, ; //  4
                    k006->ds, ;    //  5
                    lshifr, ;      //  6
                    k006->age, ;   //  7
                    k006->sex, ;   //  8
                    k006->los, ;   //  9
                    k006->ad_cr, ; // 10
                    sds1, ;        // 11
                    sds2, ;        // 12
                    j, ;           // 13
                    &lal.->kslps, ; // 14
                    k006->ad_cr1}) // 15
        endif
        select K006
        skip
      enddo
      if len(_a1) > 1 // если по данной услуге более одной КСГ, сортируем по убыванию критериев
        asort(_a1, , , {|x, y| iif(x[13] == y[13], x[3] > y[3], x[13] > y[13])})
      endif
      if len(_a1) > 0
        aadd(ar, aclone(_a1[1]))
      endif
    endif
  next
  if len(ar) > 0
    for i := 1 to len(ar)
      ar[i, 2] := ret_cena_KSG(ar[i, 1], lvr, date_usl)
      if ar[i, 2] > 0
        fl_cena := .t.
      endif
    next
    aHirKSG := aclone(ar)
    if len(aHirKSG) > 1
      asort(aHirKSG, , , {|x, y| iif(x[3] == y[3], x[13] > y[13], x[3] > y[3])})
    endif
    /*aadd(ars, '   ║КСГ: ' +print_array(aHirKSG[1]))
    for j := 2 to len(aHirKSG)
      aadd(ars, '   ║     ' +print_array(aHirKSG[j]))
    next*/
    if (kol_hir := f_put_debug_KSG(0, aHirKSG,ars)) > 1
      aadd(ars, ' └─> выбираем КСГ=' + rtrim(aHirKSG[1, 1]) + ' [КЗ=' + lstr(aHirKSG[1, 3]) + ']')
    endif
  endif
  if kol_ter > 0 .and. kol_hir > 0
    aTerKSG[1, 1] := alltrim(aTerKSG[1, 1])
    aHirKSG[1, 1] := alltrim(aHirKSG[1, 1])
    //i := int(val(substr(aTerKSG[1,1],2,3)))
    //j := int(val(substr(aHirKSG[1,1],2,3)))
    if !empty(aTerKSG[1, 6]) // т.е. диагноз + услуга
      lksg  := aTerKSG[1, 1]
      lcena := aTerKSG[1, 2]
      lkiro := list2arr(aTerKSG[1, 4])
      lkslp := aTerKSG[1, 14]
      aadd(ars, ' выбираем КСГ=' + lksg + ' (осн.диагноз+услуга ' + rtrim(aTerKSG[1, 6]) + ')')
    //elseif ascan(a_iskl_1, {|x| x[1]==j .and. eq_any(x[2],0,i) .and. lusl==x[3] }) > 0 // исключение из правил №1
    elseif ascan(a_iskl_1, {|x| x[1] == aHirKSG[1, 1] .and. (empty(x[2]) .or. x[2] == aTerKSG[1, 1])}) > 0 // исключение из правил №1
      lksg  := aHirKSG[1, 1]
      lcena := aHirKSG[1, 2]
      lkiro := list2arr(aHirKSG[1, 4])
      lkslp := aHirKSG[1, 14]
      aadd(ars, ' в соответствии с ИНСТРУКЦИЕЙ по КСГ выбираем ' + aHirKSG[1, 1] + ' вместо ' + aTerKSG[1, 1])
    else
      if aTerKSG[1, 3] > aHirKSG[1, 3] // 'если хирур.КЗ меньше терапевтического КЗ'
        lksg  := aTerKSG[1, 1]
        lcena := aTerKSG[1, 2]
        lkiro := list2arr(aTerKSG[1, 4])
        lkslp := aTerKSG[1, 14]
        aadd(ars, ' выбираем КСГ =' + aTerKSG[1, 1] + ' с БОЛЬШИМ коэффициентом затратоёмкости ' + lstr(aTerKSG[1, 3]))
      else
        lksg  := aHirKSG[1, 1]
        lcena := aHirKSG[1, 2]
        lkiro := list2arr(aHirKSG[1, 4])
        lkslp := aHirKSG[1, 14]
        aadd(ars, ' оставляем КСГ=' + aHirKSG[1, 1] + ' с коэффициентом затратоёмкости ' + lstr(aHirKSG[1, 3]))
      endif
    endif
  elseif kol_ter > 0
    aTerKSG[1, 1] := alltrim(aTerKSG[1, 1])
    lksg  := aTerKSG[1, 1]
    lcena := aTerKSG[1, 2]
    lkiro := list2arr(aTerKSG[1, 4])
    lkslp := aTerKSG[1, 14]
  elseif kol_hir > 0
    aHirKSG[1, 1] := alltrim(aHirKSG[1, 1])
    lksg  := aHirKSG[1, 1]
    lcena := aHirKSG[1, 2]
    lkiro := list2arr(aHirKSG[1, 4])
    lkslp := aHirKSG[1, 14]
  endif
  akslp := {}
  akiro := {}
  if lksg == 'ds18.001' .and. s_dializ > 0
    lksg := ''
  endif
  if !empty(lksg)
    s := ' РЕЗУЛЬТАТ: выбрана КСГ=' + lksg
    if empty(lcena)
      s += ', но не определена цена в справочнике ТФОМС'
      aadd(arerr, s)
    else
      s += ', цена ' + lstr(lcena, 11, 0) + 'р. '
      aadd(ars,s)
      s := ''
      if lksg == 'st38.001' .and. lbartell == '61' // Старческая астения (это правило уже устарело и не применяется)
        lkslp := ''                                // т.к. у данной КСГ нет КСЛП
      endif

      // 06.02.21
      if (year(lk_data) >= 2021) .and. (lower(substr(lksg, 1, 2)) == 'st' .or. lower(substr(lksg, 1, 2)) == 'ds')
        if !empty(HUMAN_2->PC1)
          humKSLP := HUMAN_2->PC1
        endif
        // Изощрение в порнографии
        // if Upper(ProcName(1)) == Upper('f_1pac_definition_KSG') .and. ! empty(lkslp)
        if Upper(ProcName(1)) == Upper('f_1pac_definition_KSG')
          if ! empty(lkslp)   // 24.02.21
            lkslp := selectKSLP( lkslp, humKSLP, ln_data, lk_data, ldate_r, mdiagnoz)
          endif
          // запомним КСЛП
          tmSel := select('HUMAN_2')
          if (tmSel)->(dbRlock())
            // G_RLock(forever)
            // HUMAN_2->PC1 := m1KSLP
            HUMAN_2->PC1 := lkslp
            (tmSel)->(dbRUnlock())
          endif
          select(tmSel)
        else
          lkslp := humKSLP
        endif
      endif

      // lkslp - содержит список допустимых КСЛП
      akslp := f_cena_kslp(@lcena, ;
                           lksg, ;
                           ldate_r, ;
                           ln_data, ;
                           lk_data, ;
                           lkslp, ;
                           amohu, ;
                           lprofil_k, ;
                           mdiagnoz, ;
                           lpar_org, ;
                           lad_cr)
      if year(lk_data) >= 2021  // added 29.01.21
          if !empty(akslp)
            for iKSLP := 1 to len(akslp) step 2
              if iKSLP != 1
                newKSLP += ', '
              endif
              newKSLP += str(akslp[iKSLP]) // построим новый КСЛП
            next
          else
            newKSLP := ''
          endif
          tmSel := select('HUMAN_2')
          if (tmSel)->(dbRlock())
            human_2->pc1 := newKSLP
          endif
          (tmSel)->(dbRUnlock())
        endif
        if !empty(akslp)
        // 05.02.21
        s += '  (КСЛП = '
        for iKSLP := 1 to len(akslp) step 2
          if iKSLP != 1
            s += ' + '
          endif
          s += str(akslp[iKSLP + 1 ], 4, 2)
        next
        // s += '  (КСЛП = ' +str(akslp[2],4,2)
        // if len(akslp) >= 4
        //   s += ' + ' +str(akslp[4],4,2)
        // endif
        s += ', цена ' + lstr(lcena, 11, 0) + 'р.)'
      endif
      if !empty(lkiro)
        vkiro := defenition_KIRO(lkiro, ldnej, lrslt, lis_err, lksg, lDoubleSluch)

        if vkiro > 0
          akiro := f_cena_kiro(@lcena, vkiro, lk_data)
          s += '  (КИРО = ' + str(akiro[2], 4, 2) + ', цена ' + lstr(lcena, 11, 0) + 'р.)'
        endif
      endif
      if !empty(s)
        aadd(ars, s)
      endif
    endif
  else
    if lusl == 2 .and. s_dializ > 0
      return {{}, {}, '', 0, {}, {}, s_dializ}
    else
      aadd(arerr, ' РЕЗУЛЬТАТ: не получилось выбрать КСГ' + iif(fl_reabil, ' для случая медицинской реабилитации', ''))
    endif
  endif
  return { ars, arerr, alltrim(lksg), lcena, akslp, akiro, s_dializ }
  //        1     2        3            4      5      6        7