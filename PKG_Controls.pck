create or replace package PKG_Controls is

  -- Author  : Murat YAKUP
  -- Created : 22.03.2023 00:54:27
  -- Purpose : Bu paket icerisinde , LOGIN ve PRODUCT paketlerindeki servislerin alt servisleri bulunmaktad?r.

  /* PKG_LOGIN */
  procedure prc_telefon_düzen(p_telNo        telefonlar.telefonno%type,
                              p_kullaniciAdi müsteri.kullaniciadi%type);
  function fnc_sifre_hash(p_sifre varchar2) return varchar2;
  function fnc_parametre_kontrol(p_müsteri     pkg_login.t_müsteri,
                                 p_sifreTekrar varchar2) return boolean;
  function fnc_sys_control return boolean;

  /* PKG_PRODUCT */
  function fnc_fiyat_aralik_kontrolü(p_fiyat number) return boolean;
  function fnc_kategori_kontrol(p_kategori varchar2) return number;
  function fnc_altkategori_kontrol(v_kategoriId  number,
                                   p_altKategori number) return number;
  procedure prc_plus_satisurun(p_id number);
end PKG_Controls;
/
create or replace package body PKG_Controls is
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  /* PKG_LOGIN */
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------

  /* Girilen telefon numarasini +90 (_,_,_)(_,_,_)(_,_)(_,_) format?nda cevirip tabloya ekler. */
  procedure prc_telefon_düzen(p_telNo        telefonlar.telefonno%type,
                              p_kullaniciAdi müsteri.kullaniciadi%type) is
    v_telefon telefonlar.telefonno%type;
  begin
    v_telefon := ('+90(' || substr(p_telNo, 1, 3) || ')-' ||
                 substr(p_telNo, 4, 3) || '-' || substr(p_telNo, 7, 4));
    insert into Telefonlar
      (MÜSTERIID, TELEFONNO)
    values
      ((select m.id from Müsteri m where m.kullaniciAdi = p_kullaniciAdi),
       v_telefon);
  end prc_telefon_düzen;
  ------------------------------------------------------------------------------------ 
  /* Girilen sifreyi ilk olarak raw type a cevirip SH256 algoritmas?n? kullanarak hashleme islemini gerceklestirir*/
  function fnc_sifre_hash(p_sifre varchar2) return varchar2 is
    v_hashSifre varchar2(100);
  begin
    v_hashSifre := DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW(p_sifre),
                                    DBMS_CRYPTO.HASH_SH256);
    return v_hashSifre;
  end fnc_sifre_hash;

  ----------------------------------------------------------------------------------
  /* Müsteri tablosuna eklenmek istenen parametrelerin kontrolunu saglar */
  function fnc_parametre_kontrol(p_müsteri     pkg_login.t_müsteri,
                                 p_sifreTekrar varchar2) return boolean is
    state          boolean;
    v_kullaniciAdi number;
  begin
    select count(*)
      into v_kullaniciAdi
      from Müsteri
     where kullaniciAdi = p_müsteri.kullaniciAdi;
    if length(p_müsteri.ad) <= 20 and length(p_müsteri.soyad) <= 20 and
       p_müsteri.dogumTarihi <= sysdate and
       (p_müsteri.cinsiyet = 'E' or p_müsteri.cinsiyet = 'K') and
       v_kullaniciAdi <= 0 and p_müsteri.sifre = p_sifreTekrar then
      state := true;
    else
      state := false;
    end if;
    return state;
  end fnc_parametre_kontrol;
  ----------------------------------------------------------------------------------------
  /* my2_context inde veri olup olmadiginin kontrolünü yapar */
  function fnc_sys_control return boolean is
    v_id  number;
    state boolean := true;
  begin
    select (SYS_CONTEXT('my2_context', 'Sistemdeki Kullanici'))
      into v_id
      from DUAL;
    if v_id >= 1 then
      state := false;
    end if;
    return state;
  end fnc_sys_control;
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  /*PKG_PRODUCT*/
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  /*Ürün ekleme servisinde ürünün fiyat kontrolü*/
  function fnc_fiyat_aralik_kontrolü(p_fiyat number) return boolean is
  begin
    return p_fiyat > 0 and p_fiyat < 10000;
  end fnc_fiyat_aralik_kontrolü;

  ------------------------------------------------------------------------------------------
  /*Ürün ekleme servisindeki ad parametresini alarak katagori kontrolü yapar. Kategori var ise o isme sahip
  katagorinin id sini döner*/
  function fnc_kategori_kontrol(p_kategori varchar2) return number is
    v_kategoriId number;
  begin
    select k.id
      into v_kategoriId
      from kategoriler k
     where UPPER(substr(p_kategori, 1, 3)) = (substr(k.ad, 1, 3));
    return v_kategoriId;
    exception
    when no_data_found then
        return null;
  end fnc_kategori_kontrol;
  ------------------------------------------------------------------------------------------
  /*fnc_kategori_kontrol den dönen id ile ürün_ekleme servisinde verilen alt katagori id sini kullanarak
  alt katagori kontrolünü yapar*/
  function fnc_altkategori_kontrol(v_kategoriId  number,
                                   p_altKategori number) return number is
    v_altKategori number;
  begin
    select id
      into v_altKategori
      from altkategoriler a
     where a.kategoriId = v_kategoriId
       and a.id = p_altKategori;
    return v_kategoriId;
    exception
    when no_data_found then
        return null;
  end fnc_altkategori_kontrol;
  ------------------------------------------------------------------------------------------  
  /*sepet_onay servisi sonucu satisi gerceklesen ürünlerin satisurun tablosunda satis miktarlar?n? bir(1) arttirir*/
  procedure prc_plus_satisurun(p_id number) is
    v_check number;
  begin
    select count(satis_miktari)
      into v_check
      from satisurun
     where urun_id = p_id;
    if v_check <= 0 then
      insert into satisurun
        (urun_id, satis_miktari, urun_ad)
      values
        (p_id, 1, (select ü.ad from ürünler ü where ü.id = p_id));
    else
      update satisurun
         set satis_miktari =
             ((select sum(satis_miktari) from satisurun where urun_id = p_id) + 1)
       where urun_id = p_id;
    end if;
    commit;
  end prc_plus_satisurun;
end PKG_Controls;
/
