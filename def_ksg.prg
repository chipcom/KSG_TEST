#include 'common.ch'
#include 'chip_mo.ch'
#include 'tableKSG.ch'
#include 'ksg_test.ch'

function createTableKSG(DOB, gender, dBegSl, dEndSl, uslOK, mDiag, aDiagAdd, aDiagOsl, aFedUsluga, aAdCrit, cFr)
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
  local lEmptyAdCrit := .t., lEmptyFedUsluga := .t.
  local i := 0

  default DOB to date()
  default gender to 1
  default dBegSl to date()
  default dEndSl to date()
  default uslOK to USL_OK_HOSPITAL  // круглосуточный стационар
  default cFr to ''

  tmpSelect := select()
  lOpenK006 := (select(aliasK006) != 0)
  nfile := prefixFileRefName(dEndSl) + 'k006'

  if ! lOpenK006  // проверим что область K006 уже открыта
    if hb_vfExists(exe_dir + nfile + sdbf) .and. hb_vfExists(exe_dir + nfile + sdbt)
      R_Use(exe_dir + nfile, {cur_dir + nfile, cur_dir + nfile + '_', cur_dir + nfile + 'AD', cur_dir + nfile + 'AD1'}, 'K006')
    else
      func_error(4, 'Отсутствует файл ' + exe_dir + nfile + sdbf)
      return aRet
    endif
  endif

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
  lEmptyFedUsluga := empty(aFedUsluga)
  lEmptyAdCrit := empty(aAdCrit)
  if (durationSl := dEndSl - dBegSl) == 0
    durationSl := 1
  endif

  (aliasK006)->(dbSelectArea())
  // set order to 1
  (aliasK006)->(ordSetFocus(1))
  (aliasK006)->(dbGoTop())
  (aliasK006)->(dbSeek(cUslOk + mDiag))

  do while ! eof() .and. left((aliasK006)->SHIFR, 2) == cUslOk .and. (aliasK006)->DS == mDiag

    if  ! (lEmptyAdCrit .and. lEmptyFedUsluga .and. empty(mDiag)) // если присутствует спискок доп. критериев или федеральных услуг диагноз должен быть
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

    aRet := add_arrKSG(aliasK006, aRet)
    (aliasK006)->(dbSkip())
  enddo

  if len(aFedUsluga) > 0
    // set order to 2
    (aliasK006)->(ordSetFocus(2))
    for i := 1 to len(aFedUsluga)
      cFedUsluga := upper(padr(aFedUsluga[i], 20))
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

  if len(aAdCrit) > 0
    // set order to 3
    (aliasK006)->(ordSetFocus(3))
    for i := 1 to len(aAdCrit)
      cAdCrit := lower(padr(aAdCrit[i], 20))
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

        aRet := add_arrKSG(aliasK006, aRet)
        (aliasK006)->(dbSkip())
      enddo
    next
  endif

  if ! empty(cFr)
    (aliasK006)->(ordSetFocus(4))
    cFr := lower(padr(cFr, 20))
    (aliasK006)->(dbGoTop())
    (aliasK006)->(dbSeek(cFr))
    do while ! eof() .and. (aliasK006)->AD_CR1 == cFr
      if !empty((aliasK006)->AD_CR1) .and. (alltrim((aliasK006)->AD_CR1) != cFr)     // выборка по количеству фракций
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

      aRet := add_arrKSG(aliasK006, aRet)
      (aliasK006)->(dbSkip())
    enddo
  endif

  if ! lOpenK006  // закрываем если открывали внутри функции
    (aliasK006)->(dbCloseArea())
  endif
  select(tmpSelect)

  return aRet

function add_arrKSG(cAlias, arr)

  if ! (cAlias)->(Eof()) .and. ! (cAlias)->(Bof())
    aadd(arr, { ;
        (cAlias)->DS, ; //  1 - код по МКБ (основной диагноз)
        (cAlias)->DS1, ; //  2 - код по МКБ ()
        (cAlias)->DS2, ; //  3 - код по МКБ ()
        (cAlias)->SY, ;    //  4 - код услуги ФФОМС (номенклатура минздрава)
        (cAlias)->AGE, ;   //  5 - возраст
        (cAlias)->SEX, ;   //  6 - пол
        (cAlias)->LOS, ;   //  7 - длительность
        alltrim((cAlias)->AD_CR), ; // 8 - иной классификационный критерий
        alltrim((cAlias)->AD_CR1), ;  // 9 - диапазон фраций
        (cAlias)->SHIFR, ; //  10 - КСГ
        (cAlias)->KZ, ;              //  11 - коэфициент затратоемкости
        0, ;                  //  12 - приоритет
        0 ;                  //  13 - стоимость законченного случая
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
  // elseif (y >= 18) .and. (y < 21)
  //   vid := '7'
  //   s := 'до21г.'
  else
    vid := '6'
    s := 'взр.'
  endif
  return vid
