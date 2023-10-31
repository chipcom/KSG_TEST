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
  local tmpSelect, lOpenK006 := .f., nfile, sp6 := space(6), cFedUsluga, cAdCrit
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
  if isnil(aAdCrit)
    aAdCrit := {}
  endif

  vid_age := vidAge(DOB, dBegSl, dEndSl)
  cUslOk := iif(uslOK == USL_OK_HOSPITAL, 'st', 'ds')
  cGender := iif(gender == 1, '1', '2')
  mDiag := padr(upper(mDiag), 6)
  cDiag := substr(mDiag, 1, 3)
  if (durationSl := dEndSl - dBegSl) == 0
    durationSl := 1
  endif

  tmpSelect := select()
  lOpenK006 := (select(aliasK006) != 0)
  nfile := prefixFileRefName(dEndSl) + 'k006'
  if ! lOpenK006  // проверим что область K006 уже открыта
    // R_Use(exe_dir + nfile, {cur_dir + nfile, cur_dir + nfile + '_', cur_dir + nfile + 'AD'}, 'K006')
    R_Use(DICT_DIR + nfile, {WORK_DIR + nfile, WORK_DIR + nfile + '_', WORK_DIR + nfile + 'AD'}, 'K006')
  endif

altd()
  (aliasK006)->(dbSelectArea())
  set order to 1
  (aliasK006)->(dbGoTop())
  (aliasK006)->(dbSeek(cUslOk + mDiag))
  do while ! eof() .and. left((aliasK006)->SHIFR, 2) == cUslOk .and. (aliasK006)->DS == mDiag

    if ! between_date((aliasK006)->DATEBEG, (aliasK006)->DATEEND, dEndSl) // услуга доступна по дате
      (aliasK006)->(dbSkip())
      loop
    endif

    if !empty((aliasK006)->AGE) .and. ((aliasK006)->AGE != vid_age)     // выборка по группе возраста
      (aliasK006)->(dbSkip())
      loop
    endif
    if !empty((aliasK006)->SEX) .and. ((aliasK006)->SEX != cGender)     // выборка по полу
      (aliasK006)->(dbSkip())
      loop
    endif

    aRet := add_arrKSG(aliasK006, aRet)
    (aliasK006)->(dbSkip())
  enddo

altd()
  if len(aFedUsluga) > 0
    for i := 1 to len(aFedUsluga)
      cFedUsluga := upper(padr(aFedUsluga[i], 20))
      set order to 2
      (aliasK006)->(dbGoTop())
      (aliasK006)->(dbSeek(cUslOk + cFedUsluga))
      do while ! eof() .and. left((aliasK006)->SHIFR, 2) == cUslOk .and. (aliasK006)->SY == cFedUsluga

        if ! between_date((aliasK006)->DATEBEG, (aliasK006)->DATEEND, dEndSl) // услуга доступна по дате
          (aliasK006)->(dbSkip())
          loop
        endif

        if !empty((aliasK006)->AGE) .and. ((aliasK006)->AGE != vid_age)     // выборка по группе возраста
          (aliasK006)->(dbSkip())
          loop
        endif
        if !empty((aliasK006)->SEX) .and. ((aliasK006)->SEX != cGender)     // выборка по полу
          (aliasK006)->(dbSkip())
          loop
        endif

        aRet := add_arrKSG(aliasK006, aRet)
        (aliasK006)->(dbSkip())
      enddo
    next
  endif

altd()
  if len(aAdCrit) > 0
    for i := 1 to len(aAdCrit)
      cAdCrit := lower(padr(aAdCrit[i], 20))
      set order to 3
      (aliasK006)->(dbGoTop())
      (aliasK006)->(dbSeek(cAdCrit))
      do while ! eof() .and. (aliasK006)->AD_CR == cAdCrit

        if left((aliasK006)->SHIFR, 2) != cUslOk
          (aliasK006)->(dbSkip())
          loop
        endif

        if ! between_date((aliasK006)->DATEBEG, (aliasK006)->DATEEND, dEndSl) // услуга доступна по дате
          (aliasK006)->(dbSkip())
          loop
        endif

        if !empty((aliasK006)->AGE) .and. ((aliasK006)->AGE != vid_age)     // выборка по группе возраста
          (aliasK006)->(dbSkip())
          loop
        endif

        if !empty((aliasK006)->SEX) .and. ((aliasK006)->SEX != cGender)     // выборка по полу
          (aliasK006)->(dbSkip())
          loop
        endif

        // if !empty((aliasK006)->AD_CR1) .and. (alltrim((aliasK006)->AD_CR1) != cFr)     // выборка по количеству фракций
        //   (aliasK006)->(dbSkip())
        //   loop
        // endif
        aRet := add_arrKSG(aliasK006, aRet)
        (aliasK006)->(dbSkip())
      enddo
    next
  endif

  // hb_Alert('Defention KSG function')

altd()
  if ! lOpenK006  // закрываем если открывали внутри функции
    (aliasK006)->(dbCloseArea())
  endif
  select(tmpSelect)

  return aRet

function add_arrKSG(cAlias, arr)

  if ! (cAlias)->(Eof()) .and. ! (cAlias)->(Bof())
    aadd(arr, {(cAlias)->SHIFR, ; //  1
        0, ;                  //  2
        (cAlias)->KZ, ;              //  3
        '', ;             // &lal.->kiros, ;       //  4
        (cAlias)->DS, ;  // mDiag, ;              //  5
        (cAlias)->SY, ;    //  6
        (cAlias)->AGE, ;   //  7
        (cAlias)->SEX, ;   //  8
        (cAlias)->LOS, ;   //  9
        alltrim((cAlias)->AD_CR), ; // 10
        alltrim((cAlias)->DS1), ;   // 11
        alltrim((cAlias)->DS2), ;   // 12
        0, ;                // j, ;                  // 13
        '', ;              // &lal.->kslps, ;       // 14
        alltrim((cAlias)->AD_CR1) ;  // 15
    })
  endif

  return arr

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
  return vid
