SUBROUTINE Influence3DGeoHatRayCen( xs, alpha, beta, Dalpha, Dbeta, P )

  ! Computes the beam influence, i.e. 
  ! the contribution of a single beam to the complex pressure
  ! This version uses Geometrically-spreading beams with a hat-shaped beam in ray-centered coordinates

  USE bellhopMod
  USE SdRdRMod
  USE ArrMod
  USE cross_products
  USE norms

  ! USE anglemod
  IMPLICIT NONE
  REAL ( KIND=8 ), INTENT( IN  ) :: alpha, beta, Dalpha, Dbeta         ! ray take-off angle
  REAL ( KIND=8 ), INTENT( IN  ) :: xs( 3 )                            ! source coordinate
  COMPLEX        , INTENT( OUT ) :: P( Pos%Ntheta, Pos%Nrd, Pos%Nr )   ! complex pressure
  INTEGER          :: Itheta, ir, is, id, irA, irB, II
  REAL ( KIND=8 )  :: nA, nB, mA, mB,rA, rB, &
       W, DS, delta, e1( 3 ), e2( 3 ), t_rcvr( 2, Pos%Ntheta ), &
       L1, L2, m, n, Amp, const, phase, phaseInt, Det_Q, Det_Qold, Ratio1
  REAL ( KIND=8 )  :: e1G( 3, Beam%Nsteps ), e2G( 3, Beam%Nsteps ), e1xe2( 3, Beam%Nsteps ), &
                      xt( 3, Beam%Nsteps ),  xtxe1( 3, Beam%Nsteps ),  xtxe2( 3, Beam%Nsteps )
  REAL ( KIND=8 )  :: q_tilde( Beam%Nsteps ), q_hat( Beam%Nsteps ), DetQ( Beam%Nsteps ), &
                      dq_tilde( Beam%Nsteps - 1 ), dq_hat( Beam%Nsteps - 1 ), &
                      SrcAngle, RcvrAngle
  COMPLEX (KIND=8) :: dtau( Beam%Nsteps - 1 ), delay

  DS     = SQRT( 2.0 ) * SIN( omega * xs( 3 ) * ray3D( 1 )%t( 3 ) )   ! Lloyd mirror pattern (for semi-coherent source)
  Ratio1 = SQRT( ABS( COS( alpha ) ) )

  ! scaling for geometric beams
  ! !!! This should all be changed to keep the vectors local in cache
  DetQ(    : ) =                                ray3D( 1 : Beam%Nsteps )%q_tilde( 1 ) * &
                                                ray3D( 1 : Beam%Nsteps )%q_hat(   2 )
  q_tilde( : ) =                       Dalpha * ray3D( 1 : Beam%Nsteps )%q_tilde( 1 ) / ray3D( 1 )%c
  q_hat(   : ) = ABS( COS( ALPHA ) ) * Dbeta  * ray3D( 1 : Beam%Nsteps )%q_hat(   2 ) / ray3D( 1 )%c

  dq_tilde = q_tilde( 2 : Beam%Nsteps )     - q_tilde( 1 : Beam%Nsteps - 1 )
  dq_hat   = q_hat(   2 : Beam%Nsteps )     - q_hat(   1 : Beam%Nsteps - 1 )
  dtau     = ray3D(   2 : Beam%Nsteps )%tau - ray3D(   1 : Beam%Nsteps - 1 )%tau

  ! Compute ray normals e1 and e2
  DO is = 1, Beam%Nsteps
     CALL RayNormal( ray3D( is )%t, ray3D( is )%phi, ray3D( is )%c, e1G( :, is ), e2G( :, is ) )
  END DO

  ! pre-calculate tangents, normals, etc.
  Stepping0: DO is = 1, Beam%Nsteps
     xt( :, is ) = ray3D( is )%x - xs   ! vector from the origin of the receiver plane to this point on the ray

     ! Get ray normals e1 and e2
     e1 = e1G( :, is )
     e2 = e2G( :, is )

     !e1xe2( :, is ) = cross_product( e1, e2 )
     e1xe2( :, is ) = ray3D( is )%c * ray3D( is )%t   ! unit tangent to ray
  END DO Stepping0

  ! tangent along receiver bearing line
  t_rcvr( 1, : ) = COS( DegRad * Pos%theta( 1 : Pos%Ntheta ) )
  t_rcvr( 2, : ) = SIN( DegRad * Pos%theta( 1 : Pos%Ntheta ) )

  ReceiverDepths: DO id = 1, Pos%Nrd
     ! precalculate tangent from receiver to each step of ray
     xt( 3, : ) = ray3D( 1 : Beam%Nsteps )%x( 3 ) - Pos%rd( id )
     DO is = 1, Beam%Nsteps
        xtxe1( :, is ) = cross_product( xt( :, is ), e1G( :, is ) )
        xtxe2( :, is ) = cross_product( xt( :, is ), e2G( :, is ) )
     END DO
  
     Radials: DO Itheta = 1, Pos%Ntheta
        ! *** Compute coordinates of intercept: nA, mA, rA ***
        is = 1
        delta = -DOT_PRODUCT( t_rcvr( :, Itheta ), e1xe2( 1 : 2, is ) )

        ! Check for ray normal || radial of rcvr line
        IF ( ABS( delta ) < 1D3 * SPACING( delta ) ) THEN
           irA = 0   ! serves as a flag that this normal can't be used
        ELSE
           nA  = -DOT_PRODUCT( t_rcvr( :, Itheta ), xtxe2( 1 : 2, is ) ) / delta
           mA  =  DOT_PRODUCT( t_rcvr( :, Itheta ), xtxe1( 1 : 2, is ) ) / delta
           rA  = -DOT_PRODUCT( xt(     :, is     ), e1xe2(   :,   is ) ) / delta
           irA = MAX( MIN( INT( ( rA - Pos%r( 1 ) ) / Pos%Delta_r ) + 1, Pos%Nr ), 1 )   ! index of nearest rcvr before normal
        END IF

        phase    = 0.0
        Det_QOld = DetQ( 1 )   ! used to track phase changes at caustics (rotations of Det_Q)

        Stepping: DO is = 2, Beam%Nsteps

           ! phase shifts at caustics
           Det_Q  = DetQ( is - 1 )
           IF ( Det_Q <= 0.0d0 .AND. Det_QOld > 0.0d0 .OR. &
                Det_Q >= 0.0d0 .AND. Det_QOld < 0.0d0 ) phase = phase + pi / 2.
           Det_Qold = Det_Q

           ! *** Compute coordinates of intercept: nB, mB, rB ***

           delta = -DOT_PRODUCT( t_rcvr( :, Itheta ), e1xe2( 1 : 2, is ) )

           ! Check for ray normal || radial of rcvr line
           IF ( ABS( delta ) < 1e-5 )  THEN
              irA = 0   ! serves as a flag that this normal can't be used
              CYCLE Stepping
           ELSE
              nB  = -DOT_PRODUCT( t_rcvr( :, Itheta ), xtxe2( 1 : 2, is ) ) / delta
              mB  =  DOT_PRODUCT( t_rcvr( :, Itheta ), xtxe1( 1 : 2, is ) ) / delta
              rB  = -DOT_PRODUCT( xt(     :, is ),     e1xe2(   :,   is ) ) / delta
              irB = MAX( MIN( INT( ( rB - Pos%r( 1 ) ) / Pos%Delta_r ) + 1, Pos%Nr ), 1 )  ! index of nearest rcvr before normal
           END IF

           ! Possilbe contribution if max possible beamwidth > min possible distance to receiver
           IF ( ( MAX( ABS( q_tilde( is - 1 ) ), ABS( q_tilde( is ) ) ) > MIN( ABS( nA ), ABS( nB ) ) .AND. &
                  MAX( ABS( q_hat(   is - 1 ) ), ABS( q_hat(   is ) ) ) > MIN( ABS( mA ), ABS( mB ) ) ) .OR. &
                  ( nA * nB < 0 ) .OR. &
                  ( mA * mB < 0 ) ) THEN

           ! detect and skip duplicate points (happens at boundary reflection)
           ! IF ( irA /= irB .AND. irA /= 0 .AND. irB /= 0 .AND. &
           !     NORM2b( ray3D( is )%x - ray3D( is - 1 )%x ) > 1.0D3 * SPACING( ray3D( is )%x( 1 ) ) ) THEN  ! too slow
           IF ( irA /= irB .AND. irA /= 0 .AND. irB /= 0 .AND. &
                NORM2b( ray3D( is )%x - ray3D( is - 1 )%x ) > 1.0e-7 ) THEN

              ! *** Compute contributions to bracketted receivers ***
              IF ( irB > irA ) THEN   ! going forwards in range
                 II = 0
              ELSE                    ! going backwards in range
                 II = 1
              END IF

              Ranges: DO ir = irA + 1 - II, irB + II, SIGN( 1, irB - irA )
                 W = ( Pos%r( ir ) - rA ) / ( rB - rA )   
                 n = ABS( nA + W * ( nB - nA ) )
                 m = ABS( mA + W * ( mB - mA ) )

                 ! Beamwidths
                 L1 = ABS( q_tilde( is - 1 ) + W * dq_tilde( is - 1 ) )
                 L2 = ABS( q_hat(   is - 1 ) + W * dq_hat(   is - 1 ) )

                 IF ( n < L1 .AND. m < L2  ) THEN   ! in beamwindow?
                    Det_Q = DetQ(   is - 1 )     + W * ( DetQ( is ) - DetQ( is - 1 )    )
                    delay = ray3D(  is - 1 )%tau + W * dtau( is - 1 )

                    ! phase shift at caustics
                    phaseInt = phase
                    IF ( Det_Q <= 0.0d0 .AND. Det_QOld > 0.0d0 .OR. &
                         Det_Q >= 0.0d0 .AND. Det_QOld < 0.0d0 ) phaseInt = phase + pi / 2.

                    Det_Q = L1 * L2 * ray3D( 1 )%c ** 2 / ( Dalpha * Dbeta )  ! based on actual beamwidth
                    const = Ratio1 * ray3D( is )%c * SQRT( 1.0 / ABS( Det_Q ) ) * ray3D( is )%Amp
                    IF ( Beam%RunType( 1 : 1 ) == 'S' ) const = DS * const   ! semi-coherent TL

                    W     = ( L1 - n ) * ( L2 - m ) / ( L1 * L2 )   ! hat function: 1 on center, 0 on edge
                    Amp   = const * W   ! hat function

                    SELECT CASE( Beam%RunType( 1 : 1 ) )
                       !!! this produces no output if NR=1 ???
                       CASE ( 'E' )      ! eigenrays
                          CALL WriteRay3D( alpha, beta, is, xs )

                       CASE ( 'A', 'a' ) ! arrivals
                          !!! need to fix following to get true RcvrAngle
                          RcvrAngle  = 0   ! RadDeg * ATAN2( rayt( 3 ), NORM2b( rayt( 1 : 2 ) ) )
                          CALL AddArr3D( omega, itheta, id, ir, Amp, ray2D( is - 1 )%Phase + phaseInt, delay, &
                               SrcAngle, RcvrAngle, ray2D( is )%NumTopBnc, ray2D( is )%NumBotBnc )

                       CASE ( 'C'  )     ! coherent TL
                          P( Itheta, id, ir ) = P( Itheta, id, ir ) + &
                            CMPLX( Amp * EXP( -i * ( omega * delay - ray3D( is - 1 )%Phase - phaseInt ) ) )

                       CASE DEFAULT      ! incoherent/semi-coherent TL
                          P( Itheta, id, ir ) = P( Itheta, id, ir ) + SNGL( const ** 2 * W )

                       END SELECT

                    END IF
              END DO Ranges
              END IF
           END IF

           nA  = nB
           mA  = mB
           rA  = rB
           irA = irB

        END DO Stepping
     END DO Radials
  END DO ReceiverDepths

END SUBROUTINE Influence3DGeoHatRayCen

!**********************************************************************!

SUBROUTINE Influence3DGeoHatCart( xs, alpha, beta, Dalpha, Dbeta, P )

  ! Computes the beam influence, i.e. 
  ! the contribution of a single beam to the complex pressure
  ! This version uses Geometrically-spreading beams with a hat-shaped beam

  USE bellhopMod
  USE SdRdRMod
  USE ArrMod
  USE cross_products
  USE norms

  ! USE anglemod
  IMPLICIT NONE
  REAL ( KIND=8 ), INTENT( IN  ) :: alpha, beta, Dalpha, Dbeta         ! ray take-off angle
  REAL ( KIND=8 ), INTENT( IN  ) :: xs( 3 )                            ! source coordinate
  COMPLEX        , INTENT( OUT ) :: P( Pos%Ntheta, Pos%Nrd, Pos%Nr )   ! complex pressure
  INTEGER            :: Itheta, ir, is, id, irT( 1 ), irTT
  REAL    ( KIND=8 ) :: s, rlen, &
       rA, rB, W, DS, x_ray( 3 ), rayt( 3 ), n_ray_z( 3 ), n_ray_theta(3 ), &
       e1( 3 ), e2( 3 ), x_rcvr( 3 ), t_rcvr( 2, Pos%Ntheta ), x_rcvr_ray( 3 ), &
       L1, L2, L_z, L_diag, e_theta( 3 ), m, n, m_prime, zMin, zMax, &
       Amp, const, phase, phaseInt, Det_Q, Det_Qold, Ratio1, dq_tilde, dq_hat, &
       SrcAngle, RcvrAngle
  COMPLEX ( KIND=8 ) :: dtau, delay
  
  SrcAngle = RadDeg * alpha          ! take-off angle in degrees
  DS     = SQRT( 2.0 ) * SIN( omega * xs( 3 ) * ray3D( 1 )%t( 3 ) )   ! Lloyd mirror pattern (for semi-coherent source)
  Ratio1 = SQRT( ABS( COS( alpha ) ) ) * SQRT( Dalpha * Dbeta ) / ray3D( 1 )%c

  ! scaling for geometric beams
  ray3D( 1 : Beam%Nsteps )%DetQ         = ray3D( 1 : Beam%Nsteps )%q_tilde( 1 ) * &
                                          ray3D( 1 : Beam%Nsteps )%q_hat(   2 )
  ray3D( 1 : Beam%Nsteps )%q_tilde( 1 ) =                       Dalpha * ray3D( 1 : Beam%Nsteps )%q_tilde( 1 ) / ray3D( 1 )%c
  ray3D( 1 : Beam%Nsteps )%q_hat(   2 ) = ABS( COS( ALPHA ) ) * Dbeta  * ray3D( 1 : Beam%Nsteps )%q_hat(   2 ) / ray3D( 1 )%c

  ! tangent along receiver bearing line
  t_rcvr( 1, : ) = COS( DegRad * Pos%theta( 1 : Pos%Ntheta ) )
  t_rcvr( 2, : ) = SIN( DegRad * Pos%theta( 1 : Pos%Ntheta ) )

  phase    = 0.0
  Det_QOld = ray3D( 1 )%DetQ   ! used to track phase changes at caustics (rotations of Det_Q)

  ! Compute nearest rcvr before normal
  rA  = NORM2b( ray3D( 1 )%x( 1 : 2 ) - xs( 1 : 2 ) )         ! range of ray point
  irT = MINLOC( Pos%r( 1 : Pos%Nr ), MASK = Pos%r( 1 : Pos%Nr ) .GT. rA )        ! index of receiver
  ir  = irT( 1 )

  Stepping: DO is = 2, Beam%Nsteps
     ! Compute nearest rcvr before normal
     rB  = NORM2b( ray3D( is )%x( 1 : 2 ) - xs( 1 : 2 ) )         ! range of ray point

     IF ( ABS( rB - rA ) > 1.0D3 * SPACING( rA ) ) THEN   ! jump to next step if duplicate point
        ! initialize the index of the receiver range
        IF ( is == 2 ) THEN
           IF ( rB > rA ) THEN   ! ray is moving right
              ir = 1             ! index all the way to the left
           ELSE                  ! ray is moving left
              ir = Pos%Nr        ! index all the way to the right
           END IF
        END IF

        x_ray = ray3D( is - 1 )%x

        ! compute normalized tangent (we need it to measure the step length)
        rayt = ray3D( is )%x - ray3D( is - 1 )%x
        rlen = NORM2b( rayt )

        IF ( rlen > 1.0D3 * SPACING( ray3D( is )%x( 1 ) ) ) THEN  ! Make sure this is not a duplicate point
           rayt = rayt / rlen                                     ! unit tangent to ray
           CALL RayNormal_unit( rayt, ray3D( is )%phi, e1, e2 )   ! Get ray normals e1 and e2

           ! phase shifts at caustics
           Det_Q  = ray3D( is - 1 )%DetQ
           IF ( Det_Q <= 0.0d0 .AND. Det_QOld > 0.0d0 .OR. Det_Q >= 0.0d0 .AND. Det_QOld < 0.0d0 ) phase = phase + pi / 2.
           Det_Qold = Det_Q

           L1 = MAX( ABS( ray3D( is - 1 )%q_tilde( 1 ) ), ABS( ray3D( is )%q_tilde( 1 ) ) ) ! beamwidths
           L2 = MAX( ABS( ray3D( is - 1 )%q_hat(   2 ) ), ABS( ray3D( is )%q_hat(   2 ) ) )

           L_diag = SQRT( L1 ** 2 + L2 ** 2 )   ! worst case is when rectangle is rotated to catch the hypotenuse

           ! n_ray_theta = CROSS_PRODUCT( rayt, e_z )     ! normal to the ray in the horizontal receiver plane
           n_ray_theta = [ -rayt( 2 ), rayt( 1 ), 0.D0 ]  ! normal to the ray in the horizontal receiver plane

           ! *** Compute contributions to bracketted receivers ***
           dq_tilde = ray3D( is )%q_tilde( 1 ) - ray3D( is - 1 )%q_tilde( 1 )
           dq_hat   = ray3D( is )%q_hat(   2 ) - ray3D( is - 1 )%q_hat(   2 )
           dtau     = ray3D( is )%tau          - ray3D( is - 1 )%tau

           Ranges: DO
              ! is r( ir ) contained in [ rA, rB ]? Then compute beam influence
              IF ( Pos%r( ir ) >= MIN( rA, rB ) .AND. Pos%r( ir ) < MAX( rA, rB ) ) THEN

                 Radials: DO Itheta = 1, Pos%Ntheta   ! Loop over radials of receiver line

                    ! check if the receiver is too distant from the ray-segment in the horizontal plane
                    ! We use ( 1 : 2 ) to get the projection in the x-y plane
                    x_rcvr( 1 : 2 ) = xs( 1 : 2 ) + Pos%r( ir ) * [ t_rcvr( 1, Itheta ), t_rcvr( 2, Itheta ) ]  ! x-y coordinate of the receiver
                    m_prime = ABS( DOT_PRODUCT( x_rcvr( 1 : 2 ) - x_ray( 1 : 2 ), n_ray_theta( 1 : 2 ) ) )  ! normal distance from rcvr to ray segment

                    IF ( m_prime > L_diag ) CYCLE Radials

                    ! The set of possible receivers is a ring
                    ! However, extrapolating the beam backwards produces contributions with s negative and large
                    ! We do not want to accept these contributions--- they have the proper range but are 180 degrees
                    ! away from this segement of the ray
                    !!! pre-calculate unit ray tangent
                    ! s = DOT_PRODUCT( x_rcvr( 1 : 2 ) - x_ray( 1 : 2 ), rayt( 1 : 2 ) / NORM2b( rayt( 1 : 2 ) ) )   ! a distance along ray    (in x-y plane)
                    ! s = DOT_PRODUCT( x_rcvr( 1 : 2 ) - xs( 1 : 2 ), [ t_rcvr( 1, Itheta ), t_rcvr( 2, Itheta ) ] ) ! a distance along radial (in x-y plane)
                    s = DOT_PRODUCT( x_rcvr( 1 : 2 ) - xs( 1 : 2 ), x_ray( 1 : 2 ) - xs( 1 : 2 ) ) ! vector to rcvr dotted into vector to ray point

                    ! The real receivers have an s-value in [0, R_len]
                    ! IF ( s < 0D0 .OR. s > NORM2B( ray3D( is )%x( 1 : 2 ) - ray3D( is - 1 )%x( 1 : 2 ) ) ) THEN
                    ! IF ( ABS( s ) > NORM2B( ray3D( is )%x( 1 : 2 ) - ray3D( is - 1 )%x( 1 : 2 ) ) ) THEN
                    
                    IF ( s < 0D0 ) then
                       CYCLE Radials
                    END IF

                    ! calculate z-limits for the beam (could be pre-cacluated for each itheta)
                    e_theta      = [ -t_rcvr( 2, Itheta ), t_rcvr( 1, Itheta ), 0.0D0 ]  ! normal to the vertical receiver plane
                    ! n_ray_z    = CROSS_PRODUCT( rayt, e_theta )                        ! normal to the ray in the vertical receiver plane
                    n_ray_z( 3 ) = rayt( 1 ) * e_theta( 2 ) - rayt( 2 ) * e_theta( 1 )   ! normal to the ray in the vertical receiver plane
                    L_z          = L_diag / ABS( n_ray_z( 3 ) )

                    zmin = MIN( ray3D( is - 1 )%x( 3 ), ray3D( is )%x( 3 ) ) - L_z  ! min depth of ray segment
                    zmax = MAX( ray3D( is - 1 )%x( 3 ), ray3D( is )%x( 3 ) ) + L_z  ! max depth of ray segment

                    ReceiverDepths: DO id = 1, Pos%Nrd
                       x_rcvr( 3 ) = DBLE( Pos%rd( id ) )   ! z coordinate of the receiver
                       IF ( x_rcvr( 3 ) < zmin .OR. x_rcvr( 3 ) > zmax ) CYCLE ReceiverDepths

                       x_rcvr_ray = x_rcvr - x_ray
                       !!! rlen factor could be built into rayt
                       s =      DOT_PRODUCT( x_rcvr_ray, rayt ) / rlen ! proportional distance along ray
                       n = ABS( DOT_PRODUCT( x_rcvr_ray, e1 ) )        ! normal distance to ray
                       m = ABS( DOT_PRODUCT( x_rcvr_ray, e2 ) )        ! normal distance to ray

                       L1 = ray3D( is - 1 )%q_tilde( 1 ) + s * dq_tilde   ! beamwidths
                       L2 = ray3D( is - 1 )%q_hat(   2 ) + s * dq_hat

                       ! Within beam window?
                       IF ( n < ABS( L1 ) .AND. m < ABS( L2 )  ) THEN
                          Det_Q = L1 * L2
                          delay = ray3D( is - 1 )%tau + s * dtau

                          ! phase shift at caustics
                          phaseInt = phase
                          IF ( Det_Q <= 0.0d0 .AND. Det_QOld > 0.0d0 .OR. &
                               Det_Q >= 0.0d0 .AND. Det_QOld < 0.0d0 ) phaseInt = phase + pi / 2.

                          L1    = ABS( L1 )
                          L2    = ABS( L2 )
                          const = Ratio1 * ray3D( is )%c / SQRT( ABS( Det_Q ) ) * ray3D( is )%Amp
                          IF ( Beam%RunType( 1 : 1 ) == 'S' ) const = DS * const   ! semi-coherent TL

                          W     = ( L1 - n ) * ( L2 - m ) / ( L1 * L2 )   ! hat function: 1 on center, 0 on edge
                          Amp   = const * W   ! hat function

                          SELECT CASE( Beam%RunType( 1 : 1 ) )
                            CASE ( 'E' )      ! eigenrays
                               CALL WriteRay3D( alpha, beta, is, xs )

                            CASE ( 'A', 'a' ) ! arrivals
                               RcvrAngle  = RadDeg * ATAN2( rayt( 3 ), NORM2b( rayt( 1 : 2 ) ) )
                               CALL AddArr3D( omega, itheta, id, ir, Amp, ray3D( is - 1 )%Phase + phaseInt, delay, &
                                    SrcAngle, RcvrAngle, ray3D( is )%NumTopBnc, ray3D( is )%NumBotBnc )

                            CASE ( 'C'  )     ! coherent TL
                               P( Itheta, id, ir ) = P( Itheta, id, ir ) + &
                                  CMPLX( Amp * EXP( -i * ( omega * delay - ray3D( is - 1 )%Phase - phaseInt ) ) )

                            CASE DEFAULT      ! incoherent/semi-coherent TL
                               P( Itheta, id, ir ) = P( Itheta, id, ir ) + SNGL( const ** 2 * W )
                            END SELECT
                       END IF
                    END DO ReceiverDepths
                 END DO Radials

              END IF
              ! bump receiver index, ir, towards rB
              IF ( Pos%r( ir ) < rB ) THEN
                 IF ( ir >= Pos%Nr ) EXIT   ! jump out of the search and go to next step on ray
                 irTT = ir + 1          ! bump right
                 IF ( Pos%r( irTT ) >= rB ) EXIT
              ELSE
                 IF ( ir <= 1  ) EXIT   ! jump out of the search and go to next step on ray
                 irTT = ir - 1          ! bump left
                 IF ( Pos%r( irTT ) <= rB ) EXIT
              END IF
              ir = irTT
           END DO Ranges

        END IF
     END IF
     rA = rB
  END DO Stepping

END SUBROUTINE Influence3DGeoHatCart

!**********************************************************************!

SUBROUTINE Influence3DGeoGaussian( xs, alpha, beta, Dalpha, Dbeta, P )

  ! Computes the beam influence, i.e. 
  ! the contribution of a single beam to the complex pressure
  ! This version uses Geometrically-spreading beams with a hat-shaped beam
  ! Uses ray-centered coordinates

  USE bellhopMod
  USE SdRdRMod
  USE ArrMod
  USE cross_products
  USE norms

  ! USE anglemod
  IMPLICIT NONE
  INTEGER,       PARAMETER       :: BeamWindow = 4           ! kills beams outside e**(-0.5 * BeamWindow**2 )
  REAL ( KIND=8 ), INTENT( IN  ) :: alpha, beta, Dalpha, Dbeta         ! ray take-off angle
  REAL ( KIND=8 ), INTENT( IN  ) :: xs( 3 )                            ! source coordinate
  COMPLEX        , INTENT( OUT ) :: P( Pos%Ntheta, Pos%Nrd, Pos%Nr )   ! complex pressure
  INTEGER            :: Itheta, ir, is, id, irA, irB, II
  REAL    ( KIND=8 ) :: nA, nB, mA, mB, rA, rB, ST, CT, &
       W, DS, delta, e1( 3 ), e2( 3 ), t_rcvr( 2, Pos%Ntheta ), xt( 3 ), &
       L1, L2, m, n, Amp, const, phase, phaseInt, Det_Q, Det_Qold, Ratio1
  REAL (KIND=8) :: e1G( 3, Beam%Nsteps ), e2G( 3, Beam%Nsteps )
  REAL (KIND=8) :: e1xe2( 3 ), lambda
  REAL (KIND=8) :: q_tilde( Beam%Nsteps ), q_hat( Beam%Nsteps ), DetQ( Beam%Nsteps ), &
                   dq_tilde( Beam%Nsteps - 1 ), dq_hat( Beam%Nsteps - 1 ), &
                   SrcAngle, RcvrAngle
  COMPLEX (KIND=8) :: dtau( Beam%Nsteps - 1 ), delay

  
  DS     = SQRT( 2.0 ) * SIN( omega * xs( 3 ) * ray3D( 1 )%t( 3 ) )   ! Lloyd mirror pattern (for semi-coherent source)
  Ratio1 = SQRT( ABS( COS( alpha ) ) ) / ( 2. * pi )

  ! scaling for geometric beams
  DetQ(    : ) =                                REAL( ray3D( 1 : Beam%Nsteps )%q_tilde( 1 ) ) * &
                                                REAL( ray3D( 1 : Beam%Nsteps )%q_hat(   2 ) )
  q_tilde( : ) =                       Dalpha * REAL( ray3D( 1 : Beam%Nsteps )%q_tilde( 1 ) ) / ray3D( 1 )%c
  q_hat(   : ) = ABS( COS( ALPHA ) ) * Dbeta  * REAL( ray3D( 1 : Beam%Nsteps )%q_hat(   2 ) ) / ray3D( 1 )%c

  dq_tilde = q_tilde( 2 : Beam%Nsteps )     - q_tilde( 1 : Beam%Nsteps - 1 )
  dq_hat   = q_hat(   2 : Beam%Nsteps )     - q_hat(   1 : Beam%Nsteps - 1 )
  dtau     = ray3D(   2 : Beam%Nsteps )%tau - ray3D(   1 : Beam%Nsteps - 1 )%tau

  ! Compute ray normals e1 and e2
  DO is = 1, Beam%Nsteps
     CALL RayNormal( ray3D( is )%t, ray3D( is )%phi, ray3D( is )%c, e1G( :, is ), e2G( :, is ) )
  END DO

  ! tangent along receiver bearing line
  t_rcvr( 1, : ) = COS( DegRad * Pos%theta( 1 : Pos%Ntheta ) )
  t_rcvr( 2, : ) = SIN( DegRad * Pos%theta( 1 : Pos%Ntheta ) )

  ReceiverDepths: DO id = 1, Pos%Nrd

     Radials: DO Itheta = 1, Pos%Ntheta
        CT = t_rcvr( 1, Itheta )
        ST = t_rcvr( 2, Itheta )

        ! Note is = 1 below-- we use the general formulas for n, m, r, etc. for the first step
        is = 1
 
        ! *** Compute coordinates of intercept: nB, mB, rB ***
        xt      = ray3D( is )%x - xs   ! vector from the origin of the receiver plane to this point on the ray
        xt( 3 ) = ray3D( is )%x( 3 ) - Pos%rd( id )

        ! Get ray normals e1 and e2
        e1 = e1G( :, is )
        e2 = e2G( :, is )

        delta = -CT * ( e1( 2 ) * e2( 3 ) - e1( 3 ) * e2( 2 ) ) + ST * ( e1( 1 ) * e2( 3 ) - e1( 3 ) * e2( 1 ) )

        ! Check for ray normal || radial of rcvr line
        IF ( ABS( delta ) < 1D3 * SPACING( delta ) ) THEN
           irA = 0   ! serves as a flag that this normal can't be used
        ELSE
           nA = ( -CT * ( xt( 2 ) * e2( 3 ) - xt( 3 ) * e2( 2 ) ) + ST * ( xt( 1 ) * e2( 3 ) - xt( 3 ) * e2( 1 ) ) ) / delta
           mA = ( -CT * ( e1( 2 ) * xt( 3 ) - e1( 3 ) * xt( 2 ) ) + ST * ( e1( 1 ) * xt( 3 ) - e1( 3 ) * xt( 1 ) ) ) / delta
           e1xe2 = ray3D( is )%c * ray3D( is )%t   ! unit tangent to ray (could be precalculated outside the loop)
           rA  = -DOT_PRODUCT( xt, e1xe2 ) / delta
           irA = MAX( MIN( INT( ( rA - Pos%r( 1 ) ) / Pos%Delta_r ) + 1, Pos%Nr ), 1 )   ! index of nearest rcvr before normal
        END IF

        phase    = 0.0
        Det_QOld = DetQ( 1 )   ! used to track phase changes at caustics (rotations of Det_Q)

        Stepping: DO is = 2, Beam%Nsteps

           ! phase shifts at caustics
           Det_Q  = DetQ( is - 1 )
           IF ( Det_Q <= 0.0d0 .AND. Det_QOld > 0.0d0 .OR. Det_Q >= 0.0d0 .AND. Det_QOld < 0.0d0 ) phase = phase + pi / 2.
           Det_Qold = Det_Q

           ! *** Compute coordinates of intercept: nB, mB, rB ***
           xt      = ray3D( is )%x - xs   ! vector from the origin of the receiver plane to this point on the ray
           xt( 3 ) = ray3D( is )%x( 3 ) - Pos%rd( id )

           e1 = e1G( :, is )   ! ray normals
           e2 = e2G( :, is )

           delta = -CT * ( e1( 2 ) * e2( 3 ) - e1( 3 ) * e2( 2 ) ) + ST * ( e1( 1 ) * e2( 3 ) - e1( 3 ) * e2( 1 ) )

           ! Check for ray normal || radial of rcvr line
           IF ( ABS( delta ) < 1D3 * SPACING( delta ) )  THEN
              irA = 0   ! serves as a flag that this normal can't be used
              CYCLE Stepping
           ELSE
              nB = ( -CT * ( xt( 2 ) * e2( 3 ) - xt( 3 ) * e2( 2 ) ) + ST * ( xt( 1 ) * e2( 3 ) - xt( 3 ) * e2( 1 ) ) ) / delta
              mB = ( -CT * ( e1( 2 ) * xt( 3 ) - e1( 3 ) * xt( 2 ) ) + ST * ( e1( 1 ) * xt( 3 ) - e1( 3 ) * xt( 1 ) ) ) / delta
              !rB = ( -xt( 1 ) * ( e1( 2 ) * e2( 3 ) - e1( 3 ) * e2( 2 ) ) + &
              !        xt( 2 ) * ( e1( 1 ) * e2( 3 ) - e1( 3 ) * e2( 1 ) ) - &
              !        xt( 3 ) * ( e1( 1 ) * e2( 2 ) - e1( 2 ) * e2( 1 ) ) ) / delta

              e1xe2 = ray3D( is )%c * ray3D( is )%t   ! unit tangent to ray (could be precalculated outside the loop)
              ! code below is equivalent but slower
              ! e1xe2 = cross_product( e1, e2 )
              ! xtxe1 = cross_product( xt, e1 )
              ! xtxe2 = cross_product( xt, e2 )
              ! delta =   -CT * e1xe2( 1 ) - ST * e1xe2( 2 )
              ! nB    = -( CT * xtxe2( 1 ) + ST * xtxe2( 2 ) ) / delta
              ! mB    =  ( CT * xtxe1( 1 ) + ST * xtxe1( 2 ) ) / delta
              rB  = -DOT_PRODUCT( xt, e1xe2 ) / delta

              !!! following assumes uniform space in Pos%r
              ! can generate an inexact result if the resulting integer is too big
              irB = MAX( MIN( INT( ( rB - Pos%r( 1 ) ) / Pos%Delta_r ) + 1, Pos%Nr ), 1 )  ! index of nearest rcvr before normal

           END IF

           ! detect and skip duplicate points (happens at boundary reflection)
           IF ( irA /= irB .AND. irA /= 0 .AND. irB /= 0 .AND. &
                NORM2b( ray3D( is )%x - ray3D( is - 1 )%x ) > 1.0D3 * SPACING( ray3D( is )%x( 1 ) ) ) THEN

              ! *** Compute contributions to bracketted receivers ***
              IF ( irB > irA ) THEN   ! going forwards in range
                 II = 0
              ELSE                    ! going backwards in range
                 II = 1
              END IF

              Ranges: DO ir = irA + 1 - II, irB + II, SIGN( 1, irB - irA )

                 W = ( Pos%r( ir ) - rA ) / ( rB - rA )   
                 n = ABS( nA + W * ( nB - nA ) )
                 m = ABS( mA + W * ( mB - mA ) )

                 ! Within beam window?
                 L1 = ABS( q_tilde( is - 1 ) + W * dq_tilde( is - 1 ) )   ! beamwidths
                 L2 = ABS( q_hat(   is - 1 ) + W * dq_hat(   is - 1 ) )

                 ! calculate the beamwidth (must be at least lambda, except in the nearfield)
                 lambda = ray3D( is - 1 )%c / ( omega / ( 2 * pi ) )   ! should be pre-calculated !

                 !!!! comment out the following 2 lines to turn the stint off
                 !L1  = MAX( L1, MIN( 0.2 * is * Beam%deltas / lambda, lambda ) )
                 !L2  = MAX( L2, MIN( 0.2 * is * Beam%deltas / lambda, lambda ) )

                 IF ( n < BeamWindow * L1 .AND. m < BeamWindow * L2  ) THEN
                    ! phase shift at caustics
                    Det_Q = DetQ(  is - 1 )     + W * ( DetQ( is )    - DetQ( is - 1 )    )
                    delay = ray3D( is - 1 )%tau + W * dtau( is - 1 )

                    phaseInt = phase
                    IF ( Det_Q <= 0.0d0 .AND. Det_QOld > 0.0d0 .OR. &
                         Det_Q >= 0.0d0 .AND. Det_QOld < 0.0d0 ) phaseInt = phase + pi / 2.

                    Det_Q = L1 * L2 * ray3D( 1 )%c ** 2 / ( Dalpha * Dbeta )  ! based on actual beamwidth
                    const = Ratio1 * ray3D( is )%c * SQRT( 1.0 / ABS( Det_Q ) ) * ray3D( is )%Amp
                    IF ( Beam%RunType( 1 : 1 ) == 'S' ) const = DS * const   ! semi-coherent TL

                    W     = EXP( -.5 * ( ( n / L1 ) ** 2 + ( m / L2 ) ** 2 ) )   ! Gaussian decay
                    Amp   = const * W   ! hat function

                    SELECT CASE( Beam%RunType( 1 : 1 ) )
                       CASE ( 'E' )      ! eigenrays
                          CALL WriteRay3D( alpha, beta, is, xs )

                       CASE ( 'A', 'a' ) ! arrivals
                          !!! need to fix following to get true RcvrAngle
                          RcvrAngle  = 0   ! RadDeg * ATAN2( rayt( 3 ), NORM2b( rayt( 1 : 2 ) ) )
                          CALL AddArr3D( omega, itheta, id, ir, Amp, ray2D( is - 1 )%Phase + phaseInt, delay, &
                               SrcAngle, RcvrAngle, ray2D( is )%NumTopBnc, ray2D( is )%NumBotBnc )

                       CASE ( 'C'  )     ! coherent TL
                          P( Itheta, id, ir ) = P( Itheta, id, ir ) + &
                             CMPLX( Amp * EXP( -i * ( omega * delay - ray3D( is - 1 )%Phase - phaseInt ) ) )

                       CASE DEFAULT      ! incoherent/semi-coherent TL
                          P( Itheta, id, ir ) = P( Itheta, id, ir ) + SNGL( const ** 2 * W )
                       END SELECT
                 END IF
              END DO Ranges
           END IF

           nA  = nB
           mA  = mB
           rA  = rB
           irA = irB

        END DO Stepping
     END DO Radials
  END DO ReceiverDepths

END SUBROUTINE Influence3DGeoGaussian

! **********************************************************************!

SUBROUTINE ScalePressure3D( Dalpha, Dbeta, c, epsilon, P, Ntheta, Nrd, Nr, RunType, freq )

  ! Scale the pressure field

  IMPLICIT NONE
  INTEGER,            INTENT( IN    ) :: Ntheta, Nrd, Nr
  REAL    ( KIND=8 ), INTENT( IN    ) :: Dalpha, Dbeta        ! angular spacing between rays
  REAL    ( KIND=8 ), INTENT( IN    ) :: freq, c              ! source frequency, nominal sound speed
  COMPLEX,            INTENT( INOUT ) :: P( Ntheta, Nrd, Nr ) ! Pressure field
  COMPLEX ( KIND=8 ), INTENT( IN    ) :: epsilon( 2 )
  CHARACTER (LEN=5 ), INTENT( IN    ) :: RunType
  COMPLEX ( KIND=8 )                  :: const

  ! Compute scale factor for field
  SELECT CASE ( RunType( 2 : 2 ) )
  CASE ( 'C' )   ! Cerveny Gaussian beams in Cartesian coordinates
     ! epsilon is normally imaginary here, so const is complex
     const = SQRT( epsilon( 1 ) * epsilon( 2 ) ) * freq * Dbeta * Dalpha / ( SQRT( c ) ) **3
     P( :, :, : ) = const * P( :, :, : )
  CASE DEFAULT
     const = 1.0
  END SELECT

  IF ( RunType( 1 : 1 ) /= 'C' ) P = SQRT( REAL( P ) ) ! For incoherent run, convert intensity to pressure

END SUBROUTINE ScalePressure3D