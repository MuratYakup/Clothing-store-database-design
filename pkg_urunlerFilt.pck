create or replace package pkg_urunlerFilt is

  -- Author  : ASUS
  -- Created : 18.03.2023 15:16:05
  -- Purpose : 

  type filtreAd_temp is table of �r�nler%rowtype;
  type r_rec is record(
    ad    �r�nler.ad%type,
    fiyat �r�nler.fiyat%type);

  procedure prc_�r�n_filtreFiyat(p_kategori varchar2, p_order varchar2);
  procedure prc_�r�n_filtreAd(p_ad varchar2);
  procedure prc_alt�st_Kategoriler;
  procedure prc_get_kategori(p_kat number);
  procedure prc_set_fiyat(p_y�zde number, p_max number, p_min number);
end pkg_urunlerFilt;
/
create or replace package body pkg_urunlerFilt is

 /*�r�nler tablasundaki �r�nler 'artan' veya 'azalan' parametrelerine g�re siralayan ve siralanmasinin istenildigi
 kategorinin de belirtilip o kategoriye g�re bu siralamayi yapan servis*/
  procedure prc_�r�n_filtreFiyat(p_kategori varchar2, p_order varchar2) is
    c1      sys_refcursor;
    v_order varchar2(10);
    v_rec   r_rec;
  begin
    if p_order = 'AZALAN' then
      v_order := 'DESC';
    elsif p_order = 'ARTAN' then
      v_order := 'ASC';
    end if;
    open c1 for('SELECT u.ad , u.fiyat FROM �r�nler u
            WHERE u.kategoriId = (SELECT id FROM kategoriler k WHERE k.ad =''' ||
                p_kategori || ''' ) 
            ORDER BY u.fiyat ' || v_order);
    loop
      fetch c1
        into v_rec;
      exit when c1%notfound;
      dbms_output.put_line(v_rec.ad || ' ==> ' || v_rec.fiyat || ' TL');
    end loop;
  end prc_�r�n_filtreFiyat;
  -------------------------------------------------------------------------------------------------------
  /*Parametre olarak �r�nler listesindeki �r�nlerin adinin icerisinde gecen deger verildiginde
  o parametreyi iceren �r�n� d�nen servis*/
  procedure prc_�r�n_filtreAd(p_ad varchar2) is
    filtreAd filtreAd_temp;
    v_count  number;
  begin
    /*Verilen parametreyi iceren �r�nlerin sayisini tutan komut*/
    EXECUTE IMMEDIATE 'SELECT count(*) FROM �r�nler WHERE �r�nler.ad LIKE ''%' || p_ad ||
                      '%'''
      into v_count;
    dbms_output.put_line(v_count || ' ' || 'adet �r�n listelendi');
    dbms_output.put_line(' ');
    /*Tablonun icerisinde o parametreye uyan �r�nlerin listelenmesi*/
    EXECUTE IMMEDIATE 'SELECT * FROM �r�nler WHERE �r�nler.ad LIKE ''%' || p_ad ||
                      '%''' bulk collect
      into filtreAd;
    for i in 1 .. filtreAd.count loop
      dbms_output.put_line(filtreAd(i)
                           .ad || ' ==>  ' || filtreAd(i).Fiyat || '  TL');
    end loop;
  end prc_�r�n_filtreAd;
  -------------------------------------------------------------------------------------------------------
  /*Kategoriler listesindeki kategorileri, b�nyesindeki alt kategorilerle d�nen servis*/
  procedure prc_alt�st_Kategoriler is
    v_countFirst  kategoriler.id%type;
    v_countTotal  kategoriler.id%type;
    v_kategori    varchar2(50);
    v_altkategori varchar2(50);
  begin
    select min(k.id) into v_countFirst from kategoriler k;
    select max(k.id) into v_countTotal from kategoriler k;
    for i in (v_countFirst) ..(v_countTotal) loop
      SELECT LISTAGG(ad, ', ') WITHIN GROUP(ORDER BY ad) AS alt_kategoriler
        into v_altkategori
        FROM altkategoriler
       WHERE KATEGORIID = i;
      select k.ad into v_kategori from kategoriler k where id = i;
      dbms_output.put_line(v_kategori ||
                           '  kategorisine ait alt kategoriler : ' ||
                           v_altkategori);
      dbms_output.new_line();
    end loop;
  end prc_alt�st_Kategoriler;
  ----------------------------------------------------------------------------------------------------
  /*Verilen katagori numarasina g�re o katagoriye ait �r�nleri fiyatlar�i ile birlikte d�nen servis*/
  procedure prc_get_kategori(p_kat number) is
    
    cursor cur_kate is
      select * from �r�nler � where �.kategoriId = p_kat;
    type kat_type is table of �r�nler%rowtype;
    kat_temp kat_type;
  begin
    open cur_kate;
    fetch cur_kate bulk collect
      into kat_temp;
    close cur_kate;
    for i in 1 .. kat_temp.count loop
      dbms_output.put_line(kat_temp(i).ad || ' ''�r�n�n�n fiyati :  ' || kat_temp(i).fiyat ||
                            ' TL');
      dbms_output.new_line;
    end loop;
  end prc_get_kategori;

  --------------------------------------------------------------------------------------------------------
  /*�r�nler tablosundaki �r�nlerin fiyatlarinin istenilen oranda arttirilmasi ama en d�s�k ve en y�ksek fiyatinda
  istenilen degeler icerisinde olmasini saglayan servis*/
  procedure prc_set_fiyat(p_y�zde number, p_max number, p_min number) is
  begin
    update �r�nler
       set fiyat = case
                     when fiyat <= p_min * (1 + p_y�zde / 100) THEN
                      p_min * (1 + p_y�zde / 100)
                     when fiyat >= p_max then
                      p_max
                     else
                      fiyat * (1 + p_y�zde / 100)
                   end;
     update �r�nler set fiyat = case
                    when fiyat >=p_max then
                    p_max
                    else
                      fiyat
                    end;
  end prc_set_fiyat;
end pkg_urunlerFilt;
/
