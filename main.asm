; -----------------------------------------------------------
; Mikrokontroller alapú rendszerek házi feladat
; Készítette: Bányi Máté
; Neptun code: H1B2DD
; Feladat leírása:
;
;	Belső memóriában lévő két darab 16 bites előjel nélküli szám osztása, 16 bites hányados és 16 bites maradék is szükséges.
; 	Bemenet: osztandó, osztó, eredmény és maradék címei (mutatók).
;	Kimenet: eredmény, maradék (a megadott címeken).
;
; -----------------------------------------------------------

$NOMOD51 ; a sztenderd 8051 regiszter definíciók nem szükségesek


$INCLUDE (SI_EFM8BB3_Defs.inc) ; regiszter és SFR definíciók

; Ugrótábla létrehozása
	CSEG AT 0
	SJMP Main

myprog SEGMENT CODE			;saját kódszegmens létrehozása
RSEG myprog 				;saját kódszegmens kiválasztása
; ------------------------------------------------------------
; Fõprogram
; ------------------------------------------------------------
; Feladata: a szükséges inicializációs lépések elvégzése és a
;			feladatot megvalósító szubrutin(ok) meghívása
; ------------------------------------------------------------
Main:
	CLR IE_EA 		; interruptok tiltása watchdog tiltás idejére
	MOV WDTCN,#0DEh ; watchdog timer tiltása
	MOV WDTCN,#0ADh
	SETB IE_EA 		; interruptok engedélyezése

	MOV 0x30, #0x88 ; osztando also byte
	MOV 0x31, #0x13 ; osztando felso byte
	MOV 0x32, #0xEE ; oszto also byte
	MOV 0x33, #0x02 ; oszto felso byte
	MOV 0x34, #0x00 ; eredmeny also byte
	MOV 0x35, #0x00 ; eredmeny felso byte
	MOV 0x36, #0x00 ; maradek also byte
	MOV 0x37, #0x00 ; maradek felso byte

					; paraméterek elõkészítése a szubrutin híváshoz
	MOV R4, #0x30 	; osztando kezdocime
	MOV R5, #0x32	; oszto kezdocime
	MOV R6, #0x34	; eredmeny kezdocim
	MOV R7, #0x36	; maradek kezdocim

	CALL div16_16 	; osztás elvégzése, az eredmény az 0x34 és 0x35, a maradék az 0x36 és 0x37 memoriacimen látható

	JMP $ 			; végtelen ciklusban várunk

; -----------------------------------------------------------
; Division szubrutin
; -----------------------------------------------------------
; Funkció: 		16 bites szám elosztása egy másik 16 bites számmal
; Bementek:		R4 - osztando szam kezdocime
;			 	R5 - oszto szam kezdocime
;				R6 - eredmeny kezdocime
;				R7 - maradek kezdocime
; Kimenetek:  	R6 es R7 regiszterben kapott memoriacimeken talalhato ertekek
; Regisztereket módosítja:
;				A, B, PSW, 2es bank regiszterei
; -----------------------------------------------------------
div16_16:
	SETB PSW.4		; Valtas 2es bankra
	MOV R0, 0x05	; Oszto also byte cimenek felhozasa 0as bank R5os regiszterebol
	MOV A, @R0		; Ertek felhozasas
	MOV R2, A		; Cim also byte erteke R2es regiszterbe mentese
	INC R0;			; Felso cimre mutatas
	MOV A, @R0		; Felso byte ertekenek felhozasa
	MOV R3, A		; Felso bye ertekenek mentese

	MOV A, R2		; Megvizsgaljuk, hogy az oszto 0-e
	ORL A, R3
	JNZ div0		; Ha nem nulla, mehet az osztas
	MOV R2, #0x00	;
	MOV R3, #0x00	;
	MOV R4, #0x00	;
	MOV R5, #0x00	;
	JMP div4		; Ha nulla az oszto, eredmenykent es maradekkent is 0-t adunk vissza

div0:
	MOV R1, 0x04	; Osztando also byte cimenek felhozasa 0as bank R4es regiszterebol
	MOV A, @R1		; Osztando also byte ertekenek felhozasa
	MOV R0, A 		; Ertek mentese
	INC R1			; Felso bytera mutatas
	MOV A, @R1		; Felso byte felhozasa
	MOV R1, A 		; Felso byte mentese
  	MOV R4,#0x00 	; Munkaregister torlese
  	MOV R5,#0x00 	;
  	MOV B,#00h  	; Balra shiftelesek szamolasara fenntartott regiszter torlese
  	CLR C       	; Carry esetleges torlese
div1:
  	MOV A,R2   		; Oszto also byte A-ba
  	RLC A      		; Also byte shiftelese balra
  	MOV R2,A   		; Eredmeny mentese
  	MOV A,R3   		; Felso byte A-ba
  	RLC A      		; Felso byte shiftelese balra, az also byte MSB bitje beshiftelesevel az LSB bit helyere
  	MOV R3,A   		; Eredmeny mentese
  	INC B      		; Szamoljuk hanyszor shifteltuk balra az osztot
  	JNC div1   		; Addig ismeteljuk, amig az osztobol nem kerul 1-es a carrybe
div2:        		; Oszto jobbra shiftelese
  	MOV A,R3   		; Oszto felso byte A-ba
  	RRC A      		; Jobbra shifteljuk a felso byteot
  	MOV R3,A   		; Mentjuk az eredmenyt
  	MOV A,R2   		; Also byte A-ba
  	RRC A      		; Also byteot is jobbra shifteljuk, igy be kerul az MSB bit helyere a felso byte LSB bitje
  	MOV R2,A   		; Also byte mentese
  	CLR C      		; Carry torlese
  	MOV A,R1 		; Elmentjuk a kivonas elott az osztandot
  	MOV R7,A		;
  	MOV A,R0 		;
  	MOV R6, A		;
  	MOV A,R0   		; Osztnado also byteja az A-ba
  	SUBB A,R2  		; Az osztando also bytejabol kivonjuk az oszto aktualisan elshiftelt also bytejat
  	MOV R0,A   		; Mentjuk az uj osztandot uj also bytejat
  	MOV A,R1   		; Felso byte az A-ba
  	SUBB A,R3  		; Kivonjuk az osztando felso bytejabol az oszto felso bytejat
  	MOV R1,A   		; Mentjuk az osztando uj felso bytejat
  	JNC div3   		; Ha a carry 0, akkor az osztandoban megvan az oszto
  	MOV A, R7		; Ha nem volt meg benne, visszatoltjuk az elmentett osztandot
  	MOV R1,A 		;
  	MOV A, R6		;
  	MOV R0,A		;
div3:
	CPL C      		; Carry invertalasa, igy az eredmeny kozvetlenuk kepezheto
	MOV A,R4		; Atmeneti eredmeny tarolo also byteja A-ba
	RLC A      		; Carry beshiftelese az also byteba
	MOV R4,A		; Eredmeny mentese
	MOV A,R5		; Felso byte A-ba
	RLC A			; Shifteles
	MOV R5,A		; Eredmney mentese
	DJNZ B,div2 	; Ezt addig ismeteljuk, amig B regiszter erteke 0-ra nem csokken

	MOV A, R0		; Osztando also byteja - mostmar a maradek - mentese R2-be, az oszto also byte helyere
	MOV R2, A		;
	MOV A, R1		; Osztando felso byteja - mostmar a maradek - mentese R3-be, az oszto felso byte helyere
	MOV R3, A		;
div4:
	MOV R0, 0x06	; Eredmeny also byte cimenek felhozasa 0as bank R6os regiszterebol
	MOV A, R4		; Eredmeny also byteja A-ba
	MOV @R0, A		; Atmasoljuk az eredmeny also byte-jat a cel cimre
	INC R0			; A felso byte cimere mutatunk
	MOV A, R5		; Eredmeny felso byteja A-ba
	MOV @R0, A 		; Atmasoljuk az eredmeny felso bytejat a cel cimre

	MOV R0, 0x07	; Maradek also byte cimenek felhozasa 0as bank R7os regiszterebol
	MOV A, R2		; Maradek also byteja A-ba
	MOV @R0, A		; Atmasoljuk a maradek also byte-jat a cel cimere
	INC R0 			; A felso byte cimere mutatunk
	MOV A, R3		; A maradek felso byte-ja A-ba
	MOV @R0, A		; Atmasoljuk az eredmeny felso bytejat a cel cimre
	CLR PSW.4		; Visszaallitjuk a 0as regiszterbankot
	RET

END
