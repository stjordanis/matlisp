      SUBROUTINE CPOLY(OPR,OPI,DEGREE,ZEROR,ZEROI,FAIL)                 CPOL  10
C FINDS THE ZEROS OF A COMPLEX POLYNOMIAL.
C OPR, OPI  -  DOUBLE PRECISION VECTORS OF REAL AND
C IMAGINARY PARTS OF THE COEFFICIENTS IN
C ORDER OF DECREASING POWERS.
C DEGREE    -  INTEGER DEGREE OF POLYNOMIAL.
C ZEROR, ZEROI  -  OUTPUT DOUBLE PRECISION VECTORS OF
C REAL AND IMAGINARY PARTS OF THE ZEROS.
C FAIL      -  OUTPUT LOGICAL PARAMETER,  TRUE  ONLY IF
C LEADING COEFFICIENT IS ZERO OR IF CPOLY
C HAS FOUND FEWER THAN DEGREE ZEROS.
C THE PROGRAM HAS BEEN WRITTEN TO REDUCE THE CHANCE OF OVERFLOW
C OCCURRING. IF IT DOES OCCUR, THERE IS STILL A POSSIBILITY THAT
C THE ZEROFINDER WILL WORK PROVIDED THE OVERFLOWED QUANTITY IS
C REPLACED BY A LARGE NUMBER.
C COMMON AREA
      COMMON/GLOBAL/PR,PI,HR,HI,QPR,QPI,QHR,QHI,SHR,SHI,
     *    SR,SI,TR,TI,PVR,PVI,ARE,MRE,ETA,INFIN,NN
      DOUBLE PRECISION SR,SI,TR,TI,PVR,PVI,ARE,MRE,ETA,INFIN,
     *    PR(50),PI(50),HR(50),HI(50),QPR(50),QPI(50),QHR(50),
     *    QHI(50),SHR(50),SHI(50)
C TO CHANGE THE SIZE OF POLYNOMIALS WHICH CAN BE SOLVED, REPLACE
C THE DIMENSION OF THE ARRAYS IN THE COMMON AREA.
      DOUBLE PRECISION XX,YY,COSR,SINR,SMALNO,BASE,XXX,ZR,ZI,BND,
     *    OPR(1),OPI(1),ZEROR(1),ZEROI(1),
     *    CMOD,SCALE,CAUCHY,DSQRT
      LOGICAL FAIL,CONV
      INTEGER DEGREE,CNT1,CNT2
C INITIALIZATION OF CONSTANTS
      CALL MCON(ETA,INFIN,SMALNO,BASE)
      ARE = ETA
      MRE = 2.0D0*DSQRT(2.0D0)*ETA
      XX = .70710678
      YY = -XX
      COSR = -.060756474
      SINR = .99756405
      FAIL = .FALSE.
      NN = DEGREE+1
C ALGORITHM FAILS IF THE LEADING COEFFICIENT IS ZERO.
      IF (OPR(1) .NE. 0.0D0 .OR. OPI(1) .NE. 0.0D0) GO TO 10
          FAIL = .TRUE.
          RETURN
C REMOVE THE ZEROS AT THE ORIGIN IF ANY.
   10 IF (OPR(NN) .NE. 0.0D0 .OR. OPI(NN) .NE. 0.0D0) GO TO 20
          IDNN2 = DEGREE-NN+2
          ZEROR(IDNN2) = 0.0D0
          ZEROI(IDNN2) = 0.0D0
          NN = NN-1
          GO TO 10
C MAKE A COPY OF THE COEFFICIENTS.
   20 DO 30 I = 1,NN
          PR(I) = OPR(I)
          PI(I) = OPI(I)
          SHR(I) = CMOD(PR(I),PI(I))
   30 CONTINUE
C SCALE THE POLYNOMIAL.
      BND = SCALE (NN,SHR,ETA,INFIN,SMALNO,BASE)
      IF (BND .EQ. 1.0D0) GO TO 40
      DO 35 I = 1,NN
          PR(I) = BND*PR(I)
          PI(I) = BND*PI(I)
   35 CONTINUE
C START THE ALGORITHM FOR ONE ZERO .
   40 IF (NN.GT. 2) GO TO 50
C CALCULATE THE FINAL ZERO AND RETURN.
          CALL CDIVID(-PR(2),-PI(2),PR(1),PI(1),ZEROR(DEGREE),
     *    ZEROI(DEGREE))
          RETURN
C CALCULATE BND, A LOWER BOUND ON THE MODULUS OF THE ZEROS.
   50 DO 60 I = 1,NN
          SHR(I) = CMOD(PR(I),PI(I))
   60 CONTINUE
      BND = CAUCHY(NN,SHR,SHI)
C OUTER LOOP TO CONTROL 2 MAJOR PASSES WITH DIFFERENT SEQUENCES
C OF SHIFTS.
      DO 100 CNT1 = 1,2
C FIRST STAGE CALCULATION, NO SHIFT.
          CALL NOSHFT(5)
C INNER LOOP TO SELECT A SHIFT.
          DO 90 CNT2 = 1,9
C SHIFT IS CHOSEN WITH MODULUS BND AND AMPLITUDE ROTATED BY
C 94 DEGREES FROM THE PREVIOUS SHIFT
               XXX = COSR*XX-SINR*YY
               YY = SINR*XX+COSR*YY
               XX = XXX
               SR = BND*XX
               SI = BND*YY
C SECOND STAGE CALCULATION, FIXED SHIFT.
               CALL FXSHFT(10*CNT2,ZR,ZI,CONV)
               IF (.NOT. CONV) GO TO 80
C THE SECOND STAGE JUMPS DIRECTLY TO THE THIRD STAGE ITERATION.
C IF SUCCESSFUL THE ZERO IS STORED AND THE POLYNOMIAL DEFLATED.
                    IDNN2 = DEGREE-NN+2
                    ZEROR(IDNN2) = ZR
                    ZEROI(IDNN2) = ZI
                    NN = NN-1
                    DO 70 I = 1,NN
                         PR(I) = QPR(I)
                         PI(I) = QPI(I)
   70               CONTINUE
                    GO TO 40
   80          CONTINUE
C IF THE ITERATION IS UNSUCCESSFUL ANOTHER SHIFT IS CHOSEN.
   90     CONTINUE
C IF 9 SHIFTS FAIL, THE OUTER LOOP IS REPEATED WITH ANOTHER
C SEQUENCE OF SHIFTS.
  100 CONTINUE
C THE ZEROFINDER HAS FAILED ON TWO MAJOR PASSES.
C RETURN EMPTY HANDED.
      FAIL = .TRUE.
      RETURN
      END
      SUBROUTINE  NOSHFT(L1)                                            NOSH1130
C COMPUTES  THE DERIVATIVE  POLYNOMIAL AS THE INITIAL H
C POLYNOMIAL AND COMPUTES L1 NO-SHIFT H POLYNOMIALS.
C COMMON AREA
      COMMON/GLOBAL/PR,PI,HR,HI,QPR,QPI,QHR,QHI,SHR,SHI,
     *    SR,SI,TR,TI,PVR,PVI,ARE,MRE,ETA,INFIN,NN
      DOUBLE PRECISION SR,SI,TR,TI,PVR,PVI,ARE,MRE,ETA,INFIN,
     *    PR(50),PI(50),HR(50),HI(50),QPR(50),QPI(50),QHR(50),
     *    QHI(50),SHR(50),SHI(50)
      DOUBLE PRECISION XNI,T1,T2,CMOD
      N = NN-1
      NM1 = N-1
      DO 10 I = 1,N
          XNI = NN-I
          HR(I) = XNI*PR(I)/FLOAT(N)
          HI(I) = XNI*PI(I)/FLOAT(N)
   10 CONTINUE
      DO 50 JJ = 1,L1
          IF (CMOD(HR(N),HI(N)) .LE. ETA*10.0D0*CMOD(PR(N),PI(N)))
     *    GO TO 30
          CALL CDIVID(-PR(NN),-PI(NN),HR(N),HI(N),TR,TI)
          DO 20 I = 1,NM1
               J = NN-I
               T1 = HR(J-1)
               T2 = HI(J-1)
               HR(J) = TR*T1-TI*T2+PR(J)
               HI(J) = TR*T2+TI*T1+PI(J)
   20     CONTINUE
          HR(1) = PR(1)
          HI(1) = PI(1)
          GO TO 50
C IF THE CONSTANT TERM IS ESSENTIALLY ZERO, SHIFT H COEFFICIENTS.
   30     DO 40 I = 1,NM1
               J = NN-I
               HR(J) = HR(J-1)
               HI(J) = HI(J-1)
   40     CONTINUE
          HR(1) = 0.0D0
          HI(1) = 0.0D0
   50 CONTINUE
      RETURN
      END
      SUBROUTINE FXSHFT(L2,ZR,ZI,CONV)                                  FXSH1550
C COMPUTES L2 FIXED-SHIFT H POLYNOMIALS AND TESTS FOR
C CONVERGENCE.
C INITIATES A VARIABLE-SHIFT ITERATION AND RETURNS WITH THE
C APPROXIMATE ZERO IF SUCCESSFUL.
C L2 - LIMIT OF FIXED SHIFT STEPS
C ZR,ZI - APPROXIMATE ZERO IF CONV IS .TRUE.
C CONV  - LOGICAL INDICATING CONVERGENCE OF STAGE 3 ITERATION
C COMMON AREA
      COMMON/GLOBAL/PR,PI,HR,HI,QPR,QPI,QHR,QHI,SHR,SHI,
     *    SR,SI,TR,TI,PVR,PVI,ARE,MRE,ETA,INFIN,NN
      DOUBLE PRECISION SR,SI,TR,TI,PVR,PVI,ARE,MRE,ETA,INFIN,
     *    PR(50),PI(50),HR(50),HI(50),QPR(50),QPI(50),QHR(50),
     *    QHI(50),SHR(50),SHI(50)
      DOUBLE PRECISION ZR,ZI,OTR,OTI,SVSR,SVSI,CMOD
          LOGICAL CONV,TEST,PASD,BOOL
      N = NN-1
C EVALUATE P AT S.
      CALL POLYEV(NN,SR,SI,PR,PI,QPR,QPI,PVR,PVI)
      TEST = .TRUE.
      PASD = .FALSE.
C CALCULATE FIRST T = -P(S)/H(S).
      CALL CALCT(BOOL)
C MAIN LOOP FOR ONE SECOND STAGE STEP.
      DO 50 J = 1,L2
          OTR = TR
          OTI = TI
C COMPUTE NEXT H POLYNOMIAL AND NEW T.
          CALL NEXTH(BOOL)
          CALL CALCT(BOOL)
          ZR = SR+TR
          ZI = SI+TI
C TEST FOR CONVERGENCE UNLESS STAGE 3 HAS FAILED ONCE OR THIS
C IS THE LAST H POLYNOMIAL .
          IF ( BOOL .OR. .NOT. TEST .OR. J .EQ. L2) GO TO 50
          IF (CMOD(TR-OTR,TI-OTI) .GE. .5D0*CMOD(ZR,ZI)) GO TO 40
               IF (.NOT. PASD) GO TO 30
C THE WEAK CONVERGENCE TEST HAS BEEN PASSED TWICE, START THE
C THIRD STAGE ITERATION, AFTER SAVING THE CURRENT H POLYNOMIAL
C AND SHIFT.
                    DO 10 I = 1,N
                         SHR(I) = HR(I)
                         SHI(I) = HI(I)
   10               CONTINUE
                    SVSR = SR
                    SVSI = SI
                    CALL VRSHFT(10,ZR,ZI,CONV)
                    IF (CONV) RETURN
C THE ITERATION FAILED TO CONVERGE. TURN OFF TESTING AND RESTORE
C H,S,PV AND T.
                    TEST = .FALSE.
                    DO 20 I = 1,N
                         HR(I) = SHR(I)
                         HI(I) = SHI(I)
   20               CONTINUE
                    SR = SVSR
                    SI = SVSI
                    CALL POLYEV(NN,SR,SI,PR,PI,QPR,QPI,PVR,PVI)
                    CALL CALCT(BOOL)
                    GO TO 50
   30          PASD = .TRUE.
               GO TO 50
   40     PASD = .FALSE.
   50 CONTINUE
C ATTEMPT AN ITERATION WITH FINAL H POLYNOMIAL FROM SECOND STAGE.
      CALL VRSHFT(10,ZR,ZI,CONV)
      RETURN
      END
      SUBROUTINE VRSHFT(L3,ZR,ZI,CONV)                                  VRSH2230
C CARRIES OUT THE THIRD STAGE ITERATION.
C L3 - LIMIT OF STEPS IN STAGE 3.
C ZR,ZI   - ON ENTRY CONTAINS THE INITIAL ITERATE, IF THE
C ITERATION CONVERGES IT CONTAINS THE FINAL ITERATE
C ON EXIT.
C CONV    -  .TRUE. IF ITERATION CONVERGES
C COMMON AREA
      COMMON/GLOBAL/PR,PI,HR,HI,QPR,QPI,QHR,QHI,SHR,SHI,
     *    SR,SI,TR,TI,PVR,PVI,ARE,MRE,ETA,INFIN,NN
      DOUBLE PRECISION SR,SI,TR,TI,PVR,PVI,ARE,MRE,ETA,INFIN,
     *    PR(50),PI(50),HR(50),HI(50),QPR(50),QPI(50),QHR(50),
     *    QHI(50),SHR(50),SHI(50)
      DOUBLE PRECISION ZR,ZI,MP,MS,OMP,RELSTP,R1,R2,CMOD,DSQRT,ERREV,TP
      LOGICAL CONV,B,BOOL
      CONV = .FALSE.
      B = .FALSE.
      SR = ZR
      SI = ZI
C MAIN LOOP FOR STAGE THREE
      DO 60 I = 1,L3
C EVALUATE P AT S AND TEST FOR CONVERGENCE.
          CALL POLYEV(NN,SR,SI,PR,PI,QPR,QPI,PVR,PVI)
          MP = CMOD(PVR,PVI)
          MS = CMOD(SR,SI)
          IF (MP .GT. 20.0D0*ERREV(NN,QPR,QPI,MS,MP,ARE,MRE))
     *       GO TO 10
C POLYNOMIAL VALUE IS SMALLER IN VALUE THAN A BOUND ON THE ERROR
C IN EVALUATING P, TERMINATE THE ITERATION.
               CONV = .TRUE.
               ZR = SR
               ZI = SI
               RETURN
   10     IF (I .EQ. 1) GO TO 40
               IF (B .OR. MP .LT.OMP .OR. RELSTP .GE. .05D0)
     *            GO TO 30
C ITERATION HAS STALLED. PROBABLY A CLUSTER OF ZEROS. DO 5 FIXED
C SHIFT STEPS INTO THE CLUSTER TO FORCE ONE ZERO TO DOMINATE.
                    TP = RELSTP
                    B = .TRUE.
                    IF (RELSTP .LT. ETA) TP = ETA
                    R1 = DSQRT(TP)
                    R2 = SR*(1.0D0+R1)-SI*R1
                    SI = SR*R1+SI*(1.0D0+R1)
                    SR = R2
                    CALL POLYEV(NN,SR,SI,PR,PI,QPR,QPI,PVR,PVI)
                    DO 20 J = 1,5
                         CALL CALCT(BOOL)
                         CALL NEXTH(BOOL)
   20               CONTINUE
      OMP = INFIN
                    GO TO 50
C EXIT IF POLYNOMIAL VALUE INCREASES SIGNIFICANTLY.
   30          IF (MP*.1D0 .GT. OMP) RETURN
   40     OMP = MP
C CALCULATE NEXT ITERATE.
   50     CALL CALCT(BOOL)
          CALL NEXTH(BOOL)
          CALL CALCT(BOOL)
          IF (BOOL) GO TO 60
          RELSTP = CMOD(TR,TI)/CMOD(SR,SI)
          SR = SR+TR
          SI = SI+TI
   60 CONTINUE
      RETURN
      END
      SUBROUTINE CALCT(BOOL)                                            CALC2890
C COMPUTES  T = -P(S)/H(S).
C BOOL   - LOGICAL, SET TRUE IF H(S) IS ESSENTIALLY ZERO.
C COMMON AREA
      COMMON/GLOBAL/PR,PI,HR,HI,QPR,QPI,QHR,QHI,SHR,SHI,
     *    SR,SI,TR,TI,PVR,PVI,ARE,MRE,ETA,INFIN,NN
      DOUBLE PRECISION SR,SI,TR,TI,PVR,PVI,ARE,MRE,ETA,INFIN,
     *    PR(50),PI(50),HR(50),HI(50),QPR(50),QPI(50),QHR(50),
     *    QHI(50),SHR(50),SHI(50)
      DOUBLE PRECISION HVR,HVI,CMOD
      LOGICAL BOOL
      N = NN-1
C EVALUATE H(S).
      CALL POLYEV(N,SR,SI,HR,HI,QHR,QHI,HVR,HVI)
      BOOL = CMOD(HVR,HVI) .LE. ARE*10.0D0*CMOD(HR(N),HI(N))
      IF (BOOL) GO TO 10
          CALL CDIVID(-PVR,-PVI,HVR,HVI,TR,TI)
          RETURN
   10 TR = 0.0D0
      TI = 0.0D0
      RETURN
      END
      SUBROUTINE NEXTH(BOOL)                                            NEXT3110
C CALCULATES THE NEXT SHIFTED H POLYNOMIAL.
C BOOL   -  LOGICAL, IF .TRUE. H(S) IS ESSENTIALLY ZERO
C COMMON AREA
      COMMON/GLOBAL/PR,PI,HR,HI,QPR,QPI,QHR,QHI,SHR,SHI,
     *    SR,SI,TR,TI,PVR,PVI,ARE,MRE,ETA,INFIN,NN
      DOUBLE PRECISION SR,SI,TR,TI,PVR,PVI,ARE,MRE,ETA,INFIN,
     *    PR(50),PI(50),HR(50),HI(50),QPR(50),QPI(50),QHR(50),
     *    QHI(50),SHR(50),SHI(50)
      DOUBLE PRECISION T1,T2
      LOGICAL BOOL
      N = NN-1
      NM1 = N-1
      IF (BOOL) GO TO 20
          DO 10 J = 2,N
               T1 = QHR(J-1)
               T2 = QHI(J-1)
               HR(J) = TR*T1-TI*T2+QPR(J)
               HI(J) = TR*T2+TI*T1+QPI(J)
   10     CONTINUE
          HR(1) = QPR(1)
          HI(1) = QPI(1)
          RETURN
C IF H(S) IS ZERO REPLACE H WITH QH.
   20 DO 30 J = 2,N
          HR(J) = QHR(J-1)
          HI(J) = QHI(J-1)
   30 CONTINUE
      HR(1) = 0.0D0
      HI(1) = 0.0D0
      RETURN
      END
      SUBROUTINE POLYEV(NN,SR,SI,PR,PI,QR,QI,PVR,PVI)                   POLY3430
C EVALUATES A POLYNOMIAL  P  AT  S  BY THE HORNER RECURRENCE
C PLACING THE PARTIAL SUMS IN Q AND THE COMPUTED VALUE IN PV.
      DOUBLE PRECISION PR(NN),PI(NN),QR(NN),QI(NN),
     *    SR,SI,PVR,PVI,T
      QR(1) = PR(1)
      QI(1) = PI(1)
      PVR = QR(1)
      PVI = QI(1)
      DO 10 I = 2,NN
          T = PVR*SR-PVI*SI+PR(I)
          PVI = PVR*SI+PVI*SR+PI(I)
          PVR = T
          QR(I) = PVR
          QI(I) = PVI
   10 CONTINUE
      RETURN
      END
      DOUBLE PRECISION FUNCTION ERREV(NN,QR,QI,MS,MP,ARE,MRE)           ERRE3610
C BOUNDS THE ERROR IN EVALUATING THE POLYNOMIAL BY THE HORNER
C RECURRENCE.
C QR,QI - THE PARTIAL SUMS
C MS    -MODULUS OF THE POINT
C MP    -MODULUS OF POLYNOMIAL VALUE
C ARE, MRE -ERROR BOUNDS ON COMPLEX ADDITION AND MULTIPLICATION
      DOUBLE PRECISION QR(NN),QI(NN),MS,MP,ARE,MRE,E,CMOD
      E = CMOD(QR(1),QI(1))*MRE/(ARE+MRE)
      DO 10 I = 1,NN
          E = E*MS+CMOD(QR(I),QI(I))
   10 CONTINUE
      ERREV = E*(ARE+MRE)-MP*MRE
      RETURN
      END
      DOUBLE PRECISION FUNCTION CAUCHY(NN,PT,Q)                         CAUC3760
C CAUCHY COMPUTES A LOWER BOUND ON THE MODULI OF THE ZEROS OF A
C POLYNOMIAL - PT IS THE MODULUS OF THE COEFFICIENTS.
      DOUBLE PRECISION Q(NN),PT(NN),X,XM,F,DX,DF,
     *   DABS,DEXP,DLOG
      PT(NN) = -PT(NN)
C COMPUTE UPPER ESTIMATE OF BOUND.
      N = NN-1
      X = DEXP( (DLOG(-PT(NN)) - DLOG(PT(1)))/FLOAT(N) )
      IF (PT(N).EQ.0.0D0) GO TO 20
C IF NEWTON STEP AT THE ORIGIN IS BETTER, USE IT.
          XM = -PT(NN)/PT(N)
          IF (XM.LT.X) X=XM
C CHOP THE INTERVAL (0,X) UNITL F LE 0.
   20 XM = X*.1D0
      F = PT(1)
      DO 30 I = 2,NN
          F = F*XM+PT(I)
   30 CONTINUE
      IF (F.LE. 0.0D0) GO TO 40
          X = XM
          GO TO 20
   40 DX = X
C DO NEWTON ITERATION UNTIL X CONVERGES TO TWO DECIMAL PLACES.
   50 IF (DABS(DX/X) .LE. .005D0) GO TO 70
          Q(1) = PT(1)
          DO 60 I = 2,NN
               Q(I) = Q(I-1)*X+PT(I)
   60     CONTINUE
          F = Q(NN)
          DF = Q(1)
          DO 65 I = 2,N
               DF = DF*X+Q(I)
   65     CONTINUE
          DX = F/DF
          X = X-DX
          GO TO 50
   70 CAUCHY = X
      RETURN
      END
      DOUBLE PRECISION FUNCTION SCALE(NN,PT,ETA,INFIN,SMALNO,BASE)      SCAL4160
C RETURNS A SCALE FACTOR TO MULTIPLY THE COEFFICIENTS OF THE
C POLYNOMIAL. THE SCALING IS DONE TO AVOID OVERFLOW AND TO AVOID
C UNDETECTED UNDERFLOW INTERFERING WITH THE CONVERGENCE
C CRITERION.  THE FACTOR IS A POWER OF THE BASE.
C PT - MODULUS OF COEFFICIENTS OF P
C ETA,INFIN,SMALNO,BASE - CONSTANTS DESCRIBING THE
C FLOATING POINT ARITHMETIC.
      DOUBLE PRECISION PT(NN),ETA,INFIN,SMALNO,BASE,HI,LO,
     *    MAX,MIN,X,SC,DSQURT,DLOG
C FIND LARGEST AND SMALLEST MODULI OF COEFFICIENTS.
      HI = DSQRT(INFIN)
      LO = SMALNO/ETA
      MAX = 0.0D0
      MIN = INFIN
      DO 10 I = 1,NN
          X = PT(I)
          IF (X .GT. MAX) MAX = X
          IF (X .NE. 0.0D0 .AND. X.LT.MIN) MIN = X
   10 CONTINUE
C SCALE ONLY IF THERE ARE VERY LARGE OR VERY SMALL COMPONENTS.
      SCALE = 1.0D0
      IF (MIN .GE. LO .AND. MAX .LE. HI) RETURN
      X = LO/MIN
      IF (X .GT. 1.0D0) GO TO 20
          SC = 1.0D0/(DSQRT(MAX)*DSQRT(MIN))
          GO TO 30
   20 SC = X
      IF (INFIN/SC .GT. MAX) SC = 1.0D0
   30 L = DLOG(SC)/DLOG(BASE) + .500
      SCALE = BASE**L
      RETURN
      END
      SUBROUTINE CDIVID(AR,AI,BR,BI,CR,CI)                              CDIV4490
C COMPLEX DIVISION C = A/B, AVOIDING OVERFLOW.
      DOUBLE PRECISION AR,AI,BR,BI,CR,CI,R,D,T,INFIN,DABS
      IF (BR .NE. 0.0D0  .OR. BI .NE. 0.0D0) GO TO 10
C DIVISION BY ZERO, C = INFINITY.
          CALL MCON (T,INFIN,T,T)
          CR = INFIN
          CI = INFIN
          RETURN
   10 IF (DABS(BR) .GE. DABS(BI)) GO TO 20
          R = BR/BI
          D = BI+R*BR
          CR = (AR*R+AI)/D
          CI = (AI*R-AR)/D
          RETURN
   20 R = BI/BR
      D = BR+R*BI
      CR = (AR+AI*R)/D
      CI = (AI-AR*R)/D
      RETURN
      END
      DOUBLE PRECISION FUNCTION CMOD(R,I)                               CMOD4700
C MODULUS OF A COMPLEX NUMBER AVOIDING OVERFLOW.
      DOUBLE PRECISION R,I,AR,AI,DABS,DSQURT
      AR = DABS(R)
      AI = DABS(I)
      IF (AR .GE. AI) GO TO 10
          CMOD = AI*DSQRT(1.0D0+(AR/AI)**2)
          RETURN
   10 IF (AR .LE. AI) GO TO 20
          CMOD = AR*DSQRT(1.0D0+(AI/AR)**2)
          RETURN
   20 CMOD = AR*DSQRT(2.0D0)
      RETURN
      END
      SUBROUTINE MCON(ETA,INFINY,SMALNO,BASE)                           MCON4840
C MCON PROVIDES MACHINE CONSTANTS USED IN VARIOUS PARTS OF THE
C PROGRAM. THE USER MAY EITHER SET THEM DIRECTLY OR USE THE
C STATEMENTS BELOW TO COMPUTE THEM. THE MEANING OF THE FOUR
C CONSTANTS ARE -
C ETA       THE MAXIMUM RELATIVE REPRESENTATION ERROR
C WHICH CAN BE DESCRIBED AS THE SMALLEST POSITIVE
C FLOATING-POINT NUMBER SUCH THAT 1.0D0 + ETA IS
C GREATER THAN 1.0D0.
C INFINY    THE LARGEST FLOATING-POINT NUMBER
C SMALNO    THE SMALLEST POSITIVE FLOATING-POINT NUMBER
C BASE      THE BASE OF THE FLOATING-POINT NUMBER SYSTEM USED
C LET T BE THE NUMBER OF BASE-DIGITS IN EACH FLOATING-POINT
C NUMBER(DOUBLE PRECISION). THEN ETA IS EITHER .5*B**(1-T)
C OR B**(1-T) DEPENDING ON WHETHER ROUNDING OR TRUNCATION
C IS USED.
C LET M BE THE LARGEST EXPONENT AND N THE SMALLEST EXPONENT
C IN THE NUMBER SYSTEM. THEN INFINY IS (1-BASE**(-T))*BASE**M
C AND SMALNO IS BASE**N.
C THE VALUES FOR BASE,T,M,N BELOW CORRESPOND TO THE IBM/360.
      DOUBLE PRECISION ETA,INFINY,SMALNO,BASE
      INTEGER M,N,T
      BASE = 16.0D0
      T = 14
      M = 63
      N = -65
      ETA = BASE**(1-T)
      INFINY = BASE*(1.0D0-BASE**(-T))*BASE**(M-1)
      SMALNO = (BASE**(N+3))/BASE**3
      RETURN
      END
