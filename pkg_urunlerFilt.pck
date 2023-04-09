create or replace package pkg_urunlerFilt is

  -- Author  : ASUS
  -- Created : 18.03.2023 15:16:05
  -- Purpose : 

  type filtreAd_temp is table of ürünler%rowtype;
  type r_rec is record(
    ad    ürünler.ad%type,
    fiyat ürünler.fiyat%type);

  procedure prc_ürün_filtreFiyat(p_kategori varchar2, p_order varchar2);
  procedure prc_ürün_filtreAd(p_ad varchar2);
  procedure prc_altüst_Kategoriler;
  procedure prc_get_kategori(p_kat number);
  procedure prc_set_fiyat(p_yüzde number, p_max number, p_min number);
end pkg_urunlerFilt;
/
create or replace package body pkg_urunlerFilt is

 /*Ürünler tablasundaki ürünler 'artan' veya 'azalan' parametrelerine göre siralayan ve siralanmasinin istenildigi
 kategorinin de belirtilip o kategoriye göre bu siralamayi yapan servis*/
  procedure prc_ürün_filtreFiyat(p_kategori varchar2, p_order varchar2) is
    c1      sys_refcursor;
    v_order varchar2(10);
    v_rec   r_rec;
  begin
    if p_order = 'AZALAN' then
      v_order := 'DESC';
    elsif p_order = 'ARTAN' then
      v_order := 'ASC';
    end if;
    open c1 for('SELECT u.ad , u.fiyat FROM ürünler u
            WHERE u.kategoriId = (SELECT id FROM kategoriler k WHERE k.ad =''' ||
                p_kategori || ''' ) 
            ORDER BY u.fiyat ' || v_order);
    loop
      fetch c1
        into v_rec;
      exit when c1%notfound;
      dbms_output.put_line(v_rec.ad || ' ==> ' || v_rec.fiyat || ' TL');
    end loop;
  end prc_ürün_filtreFiyat;
  -------------------------------------------------------------------------------------------------------
  /*Parametre olarak ürünler listesindeki ürünlerin adinin icerisinde gecen deger verildiginde
  o parametreyi iceren ürünü dönen servis*/
  procedure prc_ürün_filtreAd(p_ad varchar2) is
    filtreAd filtreAd_temp;
    v_count  number;
  begin
    /*Verilen parametreyi iceren ürünlerin sayisini tutan komut*/
    EXECUTE IMMEDIATE 'SELECT count(*) FROM ürünler WHERE ürünler.ad LIKE ''%' || p_ad ||
                      '%'''
      into v_count;
    dbms_output.put_line(v_count || ' ' || 'adet ürün listelendi');
    dbms_output.put_line(' ');
    /*Tablonun icerisinde o parametreye uyan ürünlerin listelenmesi*/
    EXECUTE IMMEDIATE 'SELECT * FROM ürünler WHERE ürünler.ad LIKE ''%' || p_ad ||
                      '%''' bulk collect
      into filtreAd;
    for i in 1 .. filtreAd.count loop
      dbms_output.put_line(filtreAd(i)
                           .ad || ' ==>  ' || filtreAd(i).Fiyat || '  TL');
    end loop;
  end prc_ürün_filtreAd;
  -------------------------------------------------------------------------------------------------------
  /*Kategoriler listesindeki kategorileri, bünyesindeki alt kategorilerle dönen servis*/
  procedure prc_altüst_Kategoriler is
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
  end prc_altüst_Kategoriler;
  ----------------------------------------------------------------------------------------------------
  /*Verilen katagori numarasina göre o katagoriye ait ürünleri fiyatlarüi ile birlikte dönen servis*/
  procedure prc_get_kategori(p_kat number) is
    
    cursor cur_kate is
      select * from ürünler ü where ü.kategoriId = p_kat;
    type kat_type is table of ürünler%rowtype;
    kat_temp kat_type;
  begin
    open cur_kate;
    fetch cur_kate bulk collect
      into kat_temp;
    close cur_kate;
    for i in 1 .. kat_temp.count loop
      dbms_output.put_line(kat_temp(i).ad || ' ''ürününün fiyati :  ' || kat_temp(i).fiyat ||
                            ' TL');
      dbms_output.new_line;
    end loop;
  end prc_get_kategori;

  --------------------------------------------------------------------------------------------------------
  /*ürünler tablosundaki ürünlerin fiyatlarinin istenilen oranda arttirilmasi ama en düsük ve en yüksek fiyatinda
  istenilen degeler icerisinde olmasini saglayan servis*/
  procedure prc_set_fiyat(p_yüzde number, p_max number, p_min number) is
  begin
    update ürünler
       set fiyat = case
                     when fiyat <= p_min * (1 + p_yüzde / 100) THEN
                      p_min * (1 + p_yüzde / 100)
                     when fiyat >= p_max then
                      p_max
                     else
                      fiyat * (1 + p_yüzde / 100)
                   end;
     update ürünler set fiyat = case
                    when fiyat >=p_max then
                    p_max
                    else
                      fiyat
                    end;
  end prc_set_fiyat;
end pkg_urunlerFilt;
/
