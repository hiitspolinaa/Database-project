 -- Tabela per grupet e klienteve me zbritje
CREATE TABLE grup_klientesh (
    grup_id NUMBER PRIMARY KEY,
    pershkrim VARCHAR2(50),
    zbritje_perqindje NUMBER(5, 2) CHECK (zbritje_perqindje BETWEEN 0 AND 100)
);
-- Tabela per klientet
CREATE TABLE klient (
    klient_id NUMBER PRIMARY KEY,
    emri VARCHAR2(50) NOT NULL,
    mbiemri VARCHAR2(50) NOT NULL,
    nr_kontakti VARCHAR2(15),
    email VARCHAR2(100),
    adresa VARCHAR2(200),
    karte_anetaresie VARCHAR2(20),
    grup_id NUMBER,
    CONSTRAINT fk_grup_klient FOREIGN KEY (grup_id) REFERENCES grup_klientesh(grup_id)
);

-- Tabela per pikat e parkimit
CREATE TABLE pika_parkimi (
    pika_id NUMBER PRIMARY KEY,
    vendodhje VARCHAR2(100) NOT NULL
);

-- Tabela per mjetet e regjistruara
CREATE TABLE mjete (
    mjet_id NUMBER PRIMARY KEY,
    klient_id NUMBER,
    targa VARCHAR2(15) UNIQUE NOT NULL,
    lloji_mjetit VARCHAR2(50),
    CONSTRAINT fk_klient_mjete FOREIGN KEY (klient_id) REFERENCES klient(klient_id)
);

-- Tabela per historikun e kartave te anetaresise
CREATE TABLE karte_anetaresie_historik (
    historik_id NUMBER PRIMARY KEY,
    klient_id NUMBER,
    data_fillimi DATE NOT NULL,
    data_mbarimi DATE,
    CONSTRAINT fk_klient_historik FOREIGN KEY (klient_id) REFERENCES klient(klient_id)
);

-- Tabela per cmimet e parkimit sipas fashave oraresh dhe pikave
CREATE TABLE cmim_parkimi (
    cmim_id NUMBER PRIMARY KEY,
    pika_id NUMBER,
    fasha_orari VARCHAR2(50),
    cmimi NUMBER(10, 2) NOT NULL,
    CONSTRAINT fk_pika_cmim FOREIGN KEY (pika_id) REFERENCES pika_parkimi(pika_id)
);

-- Tabela per abonimet mujore ose numër herësh
CREATE TABLE abonime (
    abonim_id NUMBER PRIMARY KEY,
    klient_id NUMBER,
    tipi VARCHAR2(20) CHECK (tipi IN ('Mujor', 'NumërHerësh')),
    numer_heresh NUMBER,
    data_fillimi DATE,
    data_mbarimi DATE,
    cmimi NUMBER(10, 2),
    CONSTRAINT fk_klient_abonime FOREIGN KEY (klient_id) REFERENCES klient(klient_id)
);

-- Tabela per aktivitetin e parkimit
CREATE TABLE aktivitet_parkimi (
    aktivitet_id NUMBER PRIMARY KEY,
    pika_id NUMBER,
    mjet_id NUMBER,
    data_hyrjes DATE NOT NULL,
    data_daljes DATE,
    cmimi_paguar NUMBER(10, 2),
    klient_id NUMBER,
    CONSTRAINT fk_pika_aktivitet FOREIGN KEY (pika_id) REFERENCES pika_parkimi(pika_id),
    CONSTRAINT fk_mjet_aktivitet FOREIGN KEY (mjet_id) REFERENCES mjete(mjet_id),
    CONSTRAINT fk_klient_aktivitet FOREIGN KEY (klient_id) REFERENCES klient(klient_id)
);

-- Tabela per punonjesit e parkimit
CREATE TABLE punonjes (
    punonjes_id NUMBER PRIMARY KEY,
    emri VARCHAR2(50) NOT NULL,
    mbiemri VARCHAR2(50) NOT NULL,
    pika_id NUMBER,
    CONSTRAINT fk_pika_punonjes FOREIGN KEY (pika_id) REFERENCES pika_parkimi(pika_id)
);

-- Tabela per mbylljen e aktivitetit ditor
CREATE TABLE mbyllje_ditore (
    mbyllje_id NUMBER PRIMARY KEY,
    punonjes_id NUMBER,
    pika_id NUMBER,
    data DATE NOT NULL,
    gjendja_arkes NUMBER(10, 2) NOT NULL,
    CONSTRAINT fk_punonjes_mbyllje FOREIGN KEY (punonjes_id) REFERENCES punonjes(punonjes_id),
    CONSTRAINT fk_pika_mbyllje FOREIGN KEY (pika_id) REFERENCES pika_parkimi(pika_id)
);

-- Trigger per kontrollin e mjeteve te parkuara
CREATE OR REPLACE TRIGGER kontrollo_mjet_te_parkuar
BEFORE INSERT ON aktivitet_parkimi
FOR EACH ROW
DECLARE
    numri_aktivitetesh NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO numri_aktivitetesh
    FROM aktivitet_parkimi
    WHERE mjet_id = :NEW.mjet_id AND data_daljes IS NULL;

    IF numri_aktivitetesh > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Mjeti është tashmë i parkuar në një pikë parkimi.');
    END IF;
END;
/

-- Procedura per anulimin e shitjes
CREATE OR REPLACE PROCEDURE anulo_shitje (
    p_aktivitet_id NUMBER
) AS
BEGIN
    INSERT INTO aktivitet_parkimi (
        aktivitet_id, pika_id, mjet_id, data_hyrjes, data_daljes, cmimi_paguar, klient_id
    )
    SELECT -aktivitet_id, pika_id, mjet_id, data_hyrjes, data_daljes, -cmimi_paguar, klient_id
    FROM aktivitet_parkimi
    WHERE aktivitet_id = p_aktivitet_id;

    UPDATE aktivitet_parkimi
    SET data_daljes = SYSDATE
    WHERE aktivitet_id = p_aktivitet_id;
END;
/
COMMIT;