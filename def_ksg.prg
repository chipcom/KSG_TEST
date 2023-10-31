#include 'common.ch'
#include 'chip_mo.ch'
#include 'ksg_test.ch'

function defenitionKSG(DOB, gender, dBegSl, dEndSl, uslOK, mDiag, aDiagAdd, aDiagOsl, aFedUsluga, aAdCrit, cFr)
  // DOB - дата рождения пациента
  // gender - пол пациента (1-мужской, 2-женский)
  // dBegSl - дата начала случая
  // dEndSl - дата окончания случая
  // uslOK - условия оказания (круглосуточный или дневной стационар)
  // mDiag - код по МКБ-10 основного диагноза
  // aDiagAdd - список по МКБ-10 дополнительных диагнозов 
  // aDiagOsl - список по МКБ-10 диагнозов осложнений
  // aFedUsluga - список из номенклатуры федеральных услуг
  // aAdCrit - список дополнительных критериев
  // cFr - диапазон фракций
  local aRet := {}
  local aliasK006 := 'K006'
  local cUslOk, vid_age, cGender, cDiag, iScan, durationSl
  local tmpSelect, lOpenK006 := .f., nfile, sp6 := space(6)
  local i := 0

  default DOB to date()
  default gender to 1
  default dBegSl to date()
  default dEndSl to date()
  default uslOK to USL_OK_HOSPITAL  // круглосуточный стационар

  if isnil(aDiagAdd)
    aDiagAdd := {}
  endif
  if isnil(aDiagOsl)
    aDiagOsl := {}
  endif
  if isnil(aFedUsluga)
    aFedUsluga := {}
  endif
  vid_age := vidAge(DOB, dBegSl, dEndSl)
  cUslOk := iif(uslOK == USL_OK_HOSPITAL, 'st', 'ds')
  cGender := iif(gender == 1, '1', '2')
  mDiag := padr(upper(mDiag), 6)
  cDiag := substr(mDiag, 1, 3)
  if (durationSl := dEndSl - dBegSl) == 0
    durationSl := 1
  endif

altd()
  tmpSelect := select()
  lOpenK006 := (select(aliasK006) != 0)
  nfile := prefixFileRefName(dEndSl) + 'k006'
  if ! lOpenK006  // проверим что область K006 уже открыта
    // R_Use(exe_dir + nfile, {cur_dir + nfile, cur_dir + nfile + '_', cur_dir + nfile + 'AD'}, 'K006')
    R_Use(DICT_DIR + nfile, {WORK_DIR + nfile, WORK_DIR + nfile + '_', WORK_DIR + nfile + 'AD'}, 'K006')
  endif

  // (aliasK006)->(dbGoTop())
  // do while !(aliasK006)->(Eof())
  (aliasK006)->(dbSelectArea())
  set order to 1
  // find (cUslOk + padr(mDiag, 6))
  (aliasK006)->(dbSeek(cUslOk + mDiag))
  do while ! eof() .and. left((aliasK006)->SHIFR, 2) == cUslOk .and. k006->DS == mDiag
  // (aliasK006)->(dbSeek(cUslOk + space(6)))
  // do while left((aliasK006)->SHIFR, 2) == cUslOk .and. k006->DS == space(6) .and. !eof()
  // (aliasK006)->(dbSeek(cUslOk))
  // do while left((aliasK006)->SHIFR, 2) == cUslOk .and. !eof()
  // (aliasK006)->(dbSeek(cUslOk))
  // do while ! eof() .and. left((aliasK006)->SHIFR, 2) == cUslOk //.and. ((aliasK006)->DS == mDiag) ;
    // .and. between_date((aliasK006)->DATEBEG, (aliasK006)->DATEEND, dEndSl)
  // do while left((aliasK006)->SHIFR, 2) == cUslOk .and. ((aliasK006)->DS == mDiag .or. empty((aliasK006)->DS)) ;
  //     .and. between_date((aliasK006)->DATEBEG, (aliasK006)->DATEEND, dEndSl) .and. !eof()

    // if ! between_date((aliasK006)->DATEBEG, (aliasK006)->DATEEND, dEndSl) // услуга доступна по дате
    //   (aliasK006)->(dbSkip())
    //   loop
    // endif

    // if substr((aliasK006)->shifr, 1, 2) != cUslOk // отбираем по условию оказания мед. помощи
    //   (aliasK006)->(dbSkip())
    //   loop
    // endif
    if !empty((aliasK006)->AGE) .and. ((aliasK006)->AGE != vid_age)     // выборка по группе возраста
      (aliasK006)->(dbSkip())
      loop
    endif
    if !empty((aliasK006)->SEX) .and. ((aliasK006)->SEX != cGender)     // выборка по полу
      (aliasK006)->(dbSkip())
      loop
    endif
    // if !empty((aliasK006)->DS) .and. ((aliasK006)->DS != mDiag) .and. ((aliasK006)->DS != cDiag)  // выборка по основному диагнозу
    //   (aliasK006)->(dbSkip())
    //   loop
    // endif
    // добавить фильтр по доп. диагнозам и диагнозам осложнений
    //
    //

    // if !empty((aliasK006)->SY) .and. empty((aliasK006)->DS) .and. (iScan := ascan(aFedUsluga, alltrim((aliasK006)->SY)) == 0)     // выборка по группе федеральным услугам
    //   (aliasK006)->(dbSkip())
    //   loop
    // endif

    // if !empty((aliasK006)->AD_CR) .and. (iScan := ascan(aAdCrit, alltrim((aliasK006)->AD_CR)) == 0)     // выборка по группе дополнительных критериев
    //   (aliasK006)->(dbSkip())
    //   loop
    // endif
    // if !empty((aliasK006)->AD_CR1) .and. (alltrim((aliasK006)->AD_CR1) != cFr)     // выборка по количеству фракций
    //   (aliasK006)->(dbSkip())
    //   loop
    // endif
    // if !empty((aliasK006)->LOS) .and. (val((aliasK006)->LOS) != 1) .and. (val((aliasK006)->LOS) != durationSl)     // выборка по длительности случая
    //   (aliasK006)->(dbSkip())
    //   loop
    // endif

    aadd(aRet, {(aliasK006)->SHIFR, ; //  1
                0, ;                  //  2
                (aliasK006)->KZ, ;              //  3
                '', ;             // &lal.->kiros, ;       //  4
                (aliasK006)->DS, ;  // mDiag, ;              //  5
                (aliasK006)->SY, ;    //  6
                (aliasK006)->AGE, ;   //  7
                (aliasK006)->SEX, ;   //  8
                (aliasK006)->LOS, ;   //  9
                alltrim((aliasK006)->AD_CR), ; // 10
                alltrim((aliasK006)->DS1), ;   // 11
                alltrim((aliasK006)->DS2), ;   // 12
                0, ;                // j, ;                  // 13
                '', ;              // &lal.->kslps, ;       // 14
                alltrim((aliasK006)->AD_CR1) ;  // 15
                })

    ++i
    (aliasK006)->(dbSkip())
  enddo

  // hb_Alert('Defention KSG function')

altd()
  if ! lOpenK006  // закрываем если открывали внутри функции
    (aliasK006)->(dbCloseArea())
  endif
  select(tmpSelect)

  return aRet

function vidAge(DOB, dBegSl, dEndSl)
  local ldni, y, m, d, s
  local vid := '0'

  ldni := dBegSl - DOB // для ребёнка возраст в днях
  count_ymd(DOB, dBegSl, @y, @m, @d)

  if (y < 18)  // дети
    vid := '5'
    s := 'дети'
    if ldni  <= 28
      vid := '1' // дети до 28 дней
      s := '0-28дн.'
    elseif ldni  <= 90
      vid := '2' // дети до 90 дней
      s := '29-90дн.'
    elseif y < 1
      vid := '3' // дети от 91 дня до 1 года
      s := '91день-1год'
    elseif y <= 2
      vid := '4' // дети до 2 лет
      s := 'до2лет включ.'
    endif 
  elseif (y >= 18) .and. (y < 21)
    vid := '7'
    s := 'до21г.'
  else
    vid := '6'
    s := 'взр.'
  endif

  // if lvr == 0 //
  //   lage := '6'
  //   s := 'взр.'
  // else
  //   lage := '5'
  //   s := 'дети'
  //   fl := .t.
  //   if ldni <= 28
  //     lage += '1' // дети до 28 дней
  //     s := '0-28дн.'
  //     fl := .f.
  //   elseif ldni <= 90
  //     lage += '2' // дети до 90 дней
  //     s := '29-90дн.'
  //     fl := .f.
  //   elseif y < 1 // до 1 года
  //     lage += '3' // дети от 91 дня до 1 года
  //     s := '91день-1год'
  //     fl := .f.
  //   endif
  //   if y <= 2 // до 2 лет включительно
  //     lage += '4' // дети до 2 лет
  //     if fl
  //       s := 'до2лет включ.'
  //     endif
  //   endif
  // endif

  return vid
