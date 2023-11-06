#include 'common.ch'
#include 'chip_mo.ch'
#include 'tableKSG.ch'
#include 'ksg_test.ch'

function createTableKSG(DOB, gender, dBegSl, dEndSl, uslOK, mDiag, aDiagAdd, aDiagOsl, aFedUsluga, aAdCrit, cFr)
  // DOB - ��� ஦����� ��樥��
  // gender - ��� ��樥�� (1-��᪮�, 2-���᪨�)
  // dBegSl - ��� ��砫� ����
  // dEndSl - ��� ����砭�� ����
  // uslOK - �᫮��� �������� (��㣫������ ��� ������� ��樮���)
  // mDiag - ��� �� ���-10 �᭮����� ��������
  // aDiagAdd - ᯨ᮪ �� ���-10 �������⥫��� ��������� 
  // aDiagOsl - ᯨ᮪ �� ���-10 ��������� �᫮������
  // aFedUsluga - ᯨ᮪ �� ������������ 䥤�ࠫ��� ���
  // aAdCrit - ᯨ᮪ �������⥫��� ���ਥ�
  // cFr - �������� �ࠪ権
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
  default uslOK to USL_OK_HOSPITAL  // ��㣫������ ��樮���
  default cFr to ''

  tmpSelect := select()
  lOpenK006 := (select(aliasK006) != 0)
  nfile := prefixFileRefName(dEndSl) + 'k006'

  if ! lOpenK006  // �஢�ਬ �� ������� K006 㦥 �����
    if hb_vfExists(exe_dir + nfile + sdbf) .and. hb_vfExists(exe_dir + nfile + sdbt)
      R_Use(exe_dir + nfile, {cur_dir + nfile, cur_dir + nfile + '_', cur_dir + nfile + 'AD', cur_dir + nfile + 'AD1'}, 'K006')
    else
      func_error(4, '��������� 䠩� ' + exe_dir + nfile + sdbf)
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

    if  ! (lEmptyAdCrit .and. lEmptyFedUsluga .and. empty(mDiag)) // �᫨ ��������� ᯨ᪮� ���. ���ਥ� ��� 䥤�ࠫ��� ��� ������� ������ ����
      (aliasK006)->(dbSkip())
      loop
    endif

    if ! between_date((aliasK006)->DATEBEG, (aliasK006)->DATEEND, dEndSl) // ��㣠 ����㯭� �� ���
      (aliasK006)->(dbSkip())
      loop
    endif

    if !empty((aliasK006)->AGE) .and. ((aliasK006)->AGE != vid_age)     // �롮ઠ �� ��㯯� ������
      (aliasK006)->(dbSkip())
      loop
    endif
    if !empty((aliasK006)->SEX) .and. ((aliasK006)->SEX != cGender)     // �롮ઠ �� ����
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

        if ! between_date((aliasK006)->DATEBEG, (aliasK006)->DATEEND, dEndSl) // ��㣠 ����㯭� �� ���
          (aliasK006)->(dbSkip())
          loop
        endif

        if !empty((aliasK006)->AGE) .and. ((aliasK006)->AGE != vid_age)     // �롮ઠ �� ��㯯� ������
          (aliasK006)->(dbSkip())
          loop
        endif
        if !empty((aliasK006)->SEX) .and. ((aliasK006)->SEX != cGender)     // �롮ઠ �� ����
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

        if ! between_date((aliasK006)->DATEBEG, (aliasK006)->DATEEND, dEndSl) // ��㣠 ����㯭� �� ���
          (aliasK006)->(dbSkip())
          loop
        endif

        if !empty((aliasK006)->AGE) .and. ((aliasK006)->AGE != vid_age)     // �롮ઠ �� ��㯯� ������
          (aliasK006)->(dbSkip())
          loop
        endif

        if !empty((aliasK006)->SEX) .and. ((aliasK006)->SEX != cGender)     // �롮ઠ �� ����
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
      if !empty((aliasK006)->AD_CR1) .and. (alltrim((aliasK006)->AD_CR1) != cFr)     // �롮ઠ �� �������� �ࠪ権
        (aliasK006)->(dbSkip())
        loop
      endif
      if ! between_date((aliasK006)->DATEBEG, (aliasK006)->DATEEND, dEndSl) // ��㣠 ����㯭� �� ���
        (aliasK006)->(dbSkip())
        loop
      endif

      if !empty((aliasK006)->AGE) .and. ((aliasK006)->AGE != vid_age)     // �롮ઠ �� ��㯯� ������
        (aliasK006)->(dbSkip())
        loop
      endif

      if !empty((aliasK006)->SEX) .and. ((aliasK006)->SEX != cGender)     // �롮ઠ �� ����
        (aliasK006)->(dbSkip())
        loop
      endif

      aRet := add_arrKSG(aliasK006, aRet)
      (aliasK006)->(dbSkip())
    enddo
  endif

  if ! lOpenK006  // ����뢠�� �᫨ ���뢠�� ����� �㭪樨
    (aliasK006)->(dbCloseArea())
  endif
  select(tmpSelect)

  return aRet

function add_arrKSG(cAlias, arr)

  if ! (cAlias)->(Eof()) .and. ! (cAlias)->(Bof())
    aadd(arr, { ;
        (cAlias)->DS, ; //  1 - ��� �� ��� (�᭮���� �������)
        (cAlias)->DS1, ; //  2 - ��� �� ��� ()
        (cAlias)->DS2, ; //  3 - ��� �� ��� ()
        (cAlias)->SY, ;    //  4 - ��� ��㣨 ����� (����������� �����ࠢ�)
        (cAlias)->AGE, ;   //  5 - ������
        (cAlias)->SEX, ;   //  6 - ���
        (cAlias)->LOS, ;   //  7 - ���⥫쭮���
        alltrim((cAlias)->AD_CR), ; // 8 - ���� �����䨪�樮��� ���਩
        alltrim((cAlias)->AD_CR1), ;  // 9 - �������� ��権
        (cAlias)->SHIFR, ; //  10 - ���
        (cAlias)->KZ, ;              //  11 - ����樥�� ����⮥�����
        0, ;                  //  12 - �ਮ���
        0 ;                  //  13 - �⮨����� �����祭���� ����
    })
  endif

  return arr

function vidAge(DOB, dBegSl, dEndSl)
  local ldni, y, m, d, s
  local vid := '0'

  ldni := dBegSl - DOB // ��� ॡ񭪠 ������ � ����
  count_ymd(DOB, dBegSl, @y, @m, @d)

  if (y < 18)  // ���
    vid := '5'
    s := '���'
    if ldni  <= 28
      vid := '1' // ��� �� 28 ����
      s := '0-28��.'
    elseif ldni  <= 90
      vid := '2' // ��� �� 90 ����
      s := '29-90��.'
    elseif y < 1
      vid := '3' // ��� �� 91 ��� �� 1 ����
      s := '91����-1���'
    elseif y <= 2
      vid := '4' // ��� �� 2 ���
      s := '��2��� �����.'
    endif 
  // elseif (y >= 18) .and. (y < 21)
  //   vid := '7'
  //   s := '��21�.'
  else
    vid := '6'
    s := '���.'
  endif
  return vid
