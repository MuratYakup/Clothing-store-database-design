create or replace package PKG_PRODUCT is

  -- Author  : Murat YAKUP
  -- Created : 22.03.2023 00:48:16
  -- Purpose : �r�n , sepet ve satinalma servislerinin bulundugu bu paket , parametre kontrollerini , alt servislerini
  -- pks_control paketinde bulundurmaktad?r.

  type t_�r�n is record(
    ad            �r�nler.ad%type,
    fiyat         �r�nler.fiyat%type,
    kategoriId    �r�nler.kategoriid%type,
    beden         �r�nler.beden%type,
    altkategoriId �r�nler.alt_kategoriid%type);

  procedure prc_�r�n_ekleme(p_kategori_ad varchar2, p_�r�n t_�r�n);
  procedure prc_�r�n_�ikarma(p_urunId number);
  procedure prc_sepet_�zet;
  procedure prc_sepet_Ekle(p_urun_id number);
  procedure prc_sepet_Cikar(p_urun_id number);
  procedure prc_sepet_onay;
  procedure prc_plus_satisurun(p_id number);
  function fnc_get_null_check return number;

end PKG_PRODUCT;
/
create or replace package body PKG_PRODUCT is

  /*�r�nler tablosuna t_�r�n tipindeki parametreleri ve eklenecegi kategoriyi belirledikten sonra
  gerekli kontrollerin devaminda verilen veriyi ekleme islemini yapar */
  PROCEDURE prc_�r�n_ekleme(p_kategori_ad varchar2, p_�r�n t_�r�n) IS
    v_kategoriId  NUMBER;
    v_altKategori NUMBER;
  BEGIN
    -- Kategori ve Alt Kategori Se�imi
  
    v_kategoriId  := pkg_controls.fnc_kategori_kontrol(p_kategori_ad);
    v_altKategori := pkg_controls.fnc_altkategori_kontrol(v_kategoriId,
                                                          p_�r�n.altkategoriId);
  
    if v_kategoriId is null then
    
      raise_application_error(-20004, 'Bu isme sahip kategori bulunamadi');
    else
      v_kategoriId := pkg_controls.fnc_kategori_kontrol(p_kategori_ad);
    end if;
    if v_altKategori is null then
      raise_application_error(-20002,
                              'Bu kategoriye ait b�yle bir alt kategori bulunamadi');
    else
      v_altKategori := pkg_controls.fnc_altkategori_kontrol(v_kategoriId,
                                                            p_�r�n.altkategoriId);
    end if;
  
    -- Fiyat Kontrol�
    IF NOT pkg_controls.fnc_fiyat_aralik_kontrol�(p_�r�n.fiyat) THEN
      raise_application_error(-20001, '�r�n fiyatini kontrol ediniz');
    END IF;
    -- �r�n Ekleme*/
    INSERT INTO �r�nler
      (kategoriid, ad, fiyat, beden, alt_kategoriid)
    VALUES
      (v_kategoriId,
       (p_�r�n.ad),
       p_�r�n.fiyat,
       UPPER(p_�r�n.beden),
       v_altKategori);
    commit;
    dbms_output.put_line('�r�n basariyla eklendi');
  
  EXCEPTION
    WHEN OTHERS THEN
      -- Hata Mesaji D�nd�rme
      RAISE_APPLICATION_ERROR(-20000, 'Bir hata olustu: ' || SQLERRM);
  END prc_�r�n_ekleme;
  --------------------------------------------------------------------------------------
  /* �r�nler tablosundan, serviste verilen id ye sahip �r�n�n silinmesii saglar  */
  procedure prc_�r�n_�ikarma(p_urunId number) is
  begin
    delete from �r�nler � where �.id = p_urunid;
  end prc_�r�n_�ikarma;
  -----------------------------------------------------------------------------------
  /* Sepet tablosunda bulunan verileri ekrana yazdiran servis. Ayni �r�nleri tek satirda tutar 
  birim fiyat ve toplam fiyatini yaninda yazdirir. Ekranin en altinda toplam sepet tutarini kullaniciya
  g�sterir*/
  procedure prc_sepet_�zet IS
    v_total number;
  begin
    for i in (select count(sd.sepet_id) as urunMiktari,
                     sd.fiyat,
                     sum(sd.fiyat) as toplamFiyat
                from sepet_detay sd
               where sd.sepet_id = (select (max(id) + 1) from sepet)
               group by sd.fiyat) loop
      DBMS_OUTPUT.PUT_LINE('�r�n Miktari: ' || i.urunMiktari ||
                           ', Birim Fiyat: ' || i.fiyat ||
                           ', Toplam Fiyat: ' || i.toplamFiyat);
    
    end loop;
    select sum(sd.fiyat) into v_total from sepet_detay sd;
    dbms_output.new_line;
    dbms_output.put_line('Sepet tutari : ' || v_total);
  end prc_sepet_�zet;
  -------------------------------------------------------------------------------------
  /*Servise parametre olarak verilen id ye sahip �r�n� , context' te tutulan kullanici id si ile 
  sepet tablosuna ekleme islemini gerceklestirir */
  procedure prc_sepet_Ekle(p_urun_id number) is
    v_countCheck number;
  begin
    select count(sd.urun_id)
      into v_countCheck
      from sepet_detay sd
     where sd.sepet_id = (select max(id)+1 from sepet)
       and sd.urun_id = p_urun_id;
       dbms_output.put_line(v_countCheck);
    IF v_countCheck >= 3 then
      raise_application_error(-20001,
                              'Sepete ayni �r�nden 3''ten fazla ekleyemezsiniz');
    else
      insert into sepet_detay
        (sepet_id, urun_id, fiyat)
      values
        ((select (max(id) + 1) from sepet),
         p_urun_id,
         (select �.fiyat from �r�nler � where �.id = p_urun_id));
    
    end if;
  end prc_sepet_Ekle;
  --------------------------------------------------------
  /*Servis icerisine verilen id sepette var ise sepet tablosundan cikartilir*/
  procedure prc_sepet_Cikar(p_urun_id number) is
    v_countCheck number;
  begin
    select count(urun_id)
      into v_countCheck
      from sepet_detay
     where urun_id = p_urun_id;
    IF v_countCheck <= 0 then
      raise_application_error(-20001, 'Sepette �r�n bulunmamaktadir.');
    else
      delete from sepet_detay where urun_id = p_urun_id and rownum=1 and sepet_id = (select max(id)+1 from sepet);
    end if;
  end prc_sepet_Cikar;

  ----------------------------------------------------------------
  /*Sepet tablosundaki �r�nleri , fiyat kontrol�n� yapip fiyatta bir degisiklik yok ise satinalma tablosuna
  context icerisinde tutulan kullanici id si ile ekleme yapar. Ayni zamanda satilan her �r�n�n satis�r�n tablosunda
  o �r�n�n satis adedini 1 arttirir. */
  procedure prc_sepet_onay is
    sepet_cur    sys_refcursor;
    sepet_rec    sepet_detay%rowtype;
    v_urunid     sepet_detay.urun_id%type;
    v_fiyat      sepet_detay.fiyat%type;
    v_urun_fiyat �r�nler.fiyat%type;
    v_nullCheck  number;
  BEGIN
   for i in (select distinct(urun_id), sepet_id FROM sepet_detay sd where 
     sd.sepet_id = (select max(id) + 1 from sepet) ) LOOP
      v_urunid := i.urun_id;
      select distinct(sd.fiyat) into v_fiyat from sepet_detay sd where  sd.urun_id = v_urunid;
      select distinct (fiyat) into v_urun_fiyat from �r�nler where id = v_urunid;
      v_nullCheck := fnc_get_null_check();
      
      if v_fiyat = v_urun_fiyat then
        IF v_nullCheck <= 0 then
          update m�steri
             set ilkalisveris = sysdate
           where id =
                 (select SYS_CONTEXT('my2_context', 'Sistemdeki Kullanici')
                    from DUAL);
        else
          update m�steri
             set sonalisveris = sysdate
           where id =
                 (select SYS_CONTEXT('my2_context', 'Sistemdeki Kullanici')
                    from DUAL);
        end if;
        open sepet_cur for
          select * from sepet_detay sd where urun_id = v_urunid;
        loop
          fetch sepet_cur
            into sepet_rec;
          exit when sepet_cur%notfound;
          insert into satinalma
            (musteri_id, urunkod, adet, durum)
          values
            ((select SYS_CONTEXT('my2_context', 'Sistemdeki Kullanici')
               from DUAL),
             (select �.kod from �r�nler � where �.id = v_urunid),
             1,
             'ONAYLANDI');
          pkg_controls.prc_plus_satisurun(v_urunid);
        end loop;
        close sepet_cur;
        dbms_output.put_line('�r�n fiyati uygun:     id=' || v_urunid);
        dbms_output.put_line('�r�n satin alma basarili     id=' ||
                             v_urunid);
        dbms_output.put_line('-------------------------------');
      else
        dbms_output.put_line('�r�n fiyati uygun degil:     id=' ||
                             v_urunid);
        update sepet_detay
           set fiyat =
               (select �.fiyat from �r�nler � where �.id = v_urunid)
         where urun_id = v_urunid;
        dbms_output.put_line('�r�n fiyati g�ncellendi:     id=' ||
                             v_urunid);
      END IF;
    END LOOP;
    insert into sepet
      (musteri_id, siparis_tarihi)
    values
      ((select SYS_CONTEXT('my2_context', 'Sistemdeki Kullanici') FROM DUAL),
       sysdate);
  END prc_sepet_onay;

  ------------------------------------------------------------------------------
  /*Kullanicinin ilk alisverisi mi diye kontrol yapar*/
  function fnc_get_null_check return number is
    v_nullCheck number;
  begin
    select count(ilkalisveris)
      into v_nullCheck
      from m�steri
     where id = (select SYS_CONTEXT('my2_context', 'Sistemdeki Kullanici')
                   from dual);
    return(v_nullCheck);
  end fnc_get_null_check;

  ---------------------------------------------------------------------------------
  /*prc_sepet_onay servisinde onaylanan �r�nlerin satis�r�n tablosunda satis miktarini 1 arttirir.*/
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
        (p_id, 1, (select �.ad from �r�nler � where �.id = p_id));
    else
      update satisurun
         set satis_miktari =
             ((select sum(satis_miktari) from satisurun where urun_id = p_id) + 1)
       where urun_id = p_id;
    end if;
    commit;
  end prc_plus_satisurun;
end PKG_PRODUCT;
/
