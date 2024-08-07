#include "OBCS_OPTIONS.h"
#ifdef ALLOW_SEAICE
#include "SEAICE_OPTIONS.h"
#endif

CBOP
C     !ROUTINE: OBCS_APPLY_UVICE
C     !INTERFACE:
      SUBROUTINE OBCS_APPLY_UVICE(
     U                             uFld, vFld,
     I                             myThid )

C     !DESCRIPTION:
C     *==========================================================*
C     | S/R OBCS_APPLY_UVICE
C     |   Apply OB values to corresponding field array
C     *==========================================================*

C     !USES:
      IMPLICIT NONE
C     == Global variables ==
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
c#include "GRID.h"
#include "OBCS_PARAMS.h"
#include "OBCS_GRID.h"
#include "OBCS_SEAICE.h"
#ifdef ALLOW_SEAICE
# include "SEAICE_SIZE.h"
# include "SEAICE.h"
#endif

C     !INPUT/OUTPUT PARAMETERS:
C     == Routine Arguments ==
C    uFld     :: horizontal velocity field, 1rst component (zonal)
C    vFld     :: horizontal velocity field, 2nd  component (meridional)
C    myThid   :: my Thread Id number
      _RL uFld(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      _RL vFld(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      INTEGER myThid

#if ( defined ALLOW_SEAICE && defined SEAICE_CGRID && !defined OBCS_UVICE_OLD )

C     !LOCAL VARIABLES:
C    bi, bj   :: indices of current tile
C    i, j     :: Loop counters
      INTEGER bi, bj
      INTEGER i, j
      INTEGER Iobc, Jobc
      _RL uvIceApplyFac
CEOP

      uvIceApplyFac = OBCS_uvApplyFac
c     IF ( OBCS_monitorFreq.EQ.1. ) uvIceApplyFac =  -1.
c     IF ( OBCS_monitorFreq.EQ.deltaTMom*0.5 ) uvIceApplyFac = 0.
c     IF ( OBCS_monitorFreq.EQ.deltaTMom ) uvIceApplyFac = 1.
c     WRITE(standardMessageUnit,*)
c          'OBCS_APPLY_UVICE: uvIceApplyFac=', uvIceApplyFac

      DO bj=myByLo(myThid),myByHi(myThid)
       DO bi=myBxLo(myThid),myBxHi(myThid)

        IF ( useSeaiceNeumann ) THEN
C--   Neumann BC for seaice: before applying OB-value to ice-velocity, copy
C     interior ice-velocity field (next to OB) to OB-array: OB[N,S,E,W][u,v]ice

# ifdef ALLOW_OBCS_NORTH
         IF ( tileHasOBN(bi,bj) ) THEN
C     Northern boundary
          DO i=1-OLx,sNx+OLx
           Jobc = OB_Jn(i,bi,bj)
           IF ( Jobc.NE.OB_indexNone ) THEN
            OBNuice(i,bi,bj) = uFld(i,Jobc-1,bi,bj)
            OBNvice(i,bi,bj) = vFld(i,Jobc-1,bi,bj)
           ENDIF
          ENDDO
         ENDIF
# endif /* ALLOW_OBCS_NORTH */

# ifdef ALLOW_OBCS_SOUTH
         IF ( tileHasOBS(bi,bj) ) THEN
C     Southern boundary
          DO i=1-OLx,sNx+OLx
           Jobc = OB_Js(i,bi,bj)
           IF ( Jobc.NE.OB_indexNone ) THEN
            OBSuice(i,bi,bj) = uFld(i,Jobc+1,bi,bj)
            OBSvice(i,bi,bj) = vFld(i,Jobc+2,bi,bj)
           ENDIF
          ENDDO
         ENDIF
# endif /* ALLOW_OBCS_SOUTH */

# ifdef ALLOW_OBCS_EAST
         IF ( tileHasOBE(bi,bj) ) THEN
C     Eastern boundary
          DO j=1-OLy,sNy+OLy
           Iobc = OB_Ie(j,bi,bj)
           IF ( Iobc.NE.OB_indexNone ) THEN
            OBEuice(j,bi,bj) = uFld(Iobc-1,j,bi,bj)
            OBEvice(j,bi,bj) = vFld(Iobc-1,j,bi,bj)
           ENDIF
          ENDDO
         ENDIF
# endif /* ALLOW_OBCS_EAST */

# ifdef ALLOW_OBCS_WEST
         IF ( tileHasOBW(bi,bj) ) THEN
C     Western boundary
          DO j=1-OLy,sNy+OLy
           Iobc = OB_Iw(j,bi,bj)
           IF ( Iobc.NE.OB_indexNone ) THEN
            OBWuice(j,bi,bj) = uFld(Iobc+2,j,bi,bj)
            OBWvice(j,bi,bj) = vFld(Iobc+1,j,bi,bj)
           ENDIF
          ENDDO
         ENDIF
# endif /* ALLOW_OBCS_WEST */

C-      end if useSeaiceNeumann block
        ENDIF

C--   Set model variables to OB values on N/S/E/W Boundaries:
C     2 steps: 1) set tangential component ; 2) set normal component.
C     This ensures that the normal component is set correctly even
C     when it conficts with tangential setting from an other OB.

C--   Set Tangential component first:

C     Set model variables to OB values on North/South Boundaries
# ifdef ALLOW_OBCS_NORTH
        IF ( tileHasOBN(bi,bj) ) THEN
C     Northern boundary
         DO i=1-OLx,sNx+OLx
          Jobc = OB_Jn(i,bi,bj)
          IF ( Jobc.NE.OB_indexNone ) THEN
           uFld(i,Jobc,bi,bj) = OBNuice(i,bi,bj)
     &                        *seaiceMaskU(i,Jobc,bi,bj)
          ENDIF
         ENDDO
        ENDIF
# endif /* ALLOW_OBCS_NORTH */

# ifdef ALLOW_OBCS_SOUTH
        IF ( tileHasOBS(bi,bj) ) THEN
C     Southern boundary
         DO i=1-OLx,sNx+OLx
          Jobc = OB_Js(i,bi,bj)
          IF ( Jobc.NE.OB_indexNone ) THEN
           uFld(i,Jobc,bi,bj) = OBSuice(i,bi,bj)
     &                        *seaiceMaskU(i,Jobc,bi,bj)
          ENDIF
         ENDDO
        ENDIF
# endif /* ALLOW_OBCS_SOUTH */

C     Set model variables to OB values on East/West Boundaries
# ifdef ALLOW_OBCS_EAST
        IF ( tileHasOBE(bi,bj) ) THEN
C     Eastern boundary
         DO j=1-OLy,sNy+OLy
          Iobc = OB_Ie(j,bi,bj)
          IF ( Iobc.NE.OB_indexNone ) THEN
           vFld(Iobc,j,bi,bj) = OBEvice(j,bi,bj)
     &                        *seaiceMaskV(Iobc,j,bi,bj)
          ENDIF
         ENDDO
        ENDIF
# endif /* ALLOW_OBCS_EAST */

# ifdef ALLOW_OBCS_WEST
        IF ( tileHasOBW(bi,bj) ) THEN
C     Western boundary
         DO j=1-OLy,sNy+OLy
          Iobc = OB_Iw(j,bi,bj)
          IF ( Iobc.NE.OB_indexNone ) THEN
           vFld(Iobc,j,bi,bj) = OBWvice(j,bi,bj)
     &                        *seaiceMaskV(Iobc,j,bi,bj)
          ENDIF
         ENDDO
        ENDIF
# endif /* ALLOW_OBCS_WEST */

C--   Then set Normal component:

C     Set model variables to OB values on North/South Boundaries
# ifdef ALLOW_OBCS_NORTH
        IF ( tileHasOBN(bi,bj) ) THEN
C     Northern boundary
         DO i=1-OLx,sNx+OLx
          Jobc = OB_Jn(i,bi,bj)
          IF ( Jobc.NE.OB_indexNone ) THEN
           vFld(i,Jobc,bi,bj)   = OBNvice(i,bi,bj)
     &                          *seaiceMaskV(i,Jobc,bi,bj)
           IF ( uvIceApplyFac.GE.0. )
     &     vFld(i,Jobc+1,bi,bj) = OBNvice(i,bi,bj)
     &                          *seaiceMaskV(i,Jobc,bi,bj)
     &                          *uvIceApplyFac
          ENDIF
         ENDDO
        ENDIF
# endif /* ALLOW_OBCS_NORTH */

# ifdef ALLOW_OBCS_SOUTH
        IF ( tileHasOBS(bi,bj) ) THEN
C     Southern boundary
         DO i=1-OLx,sNx+OLx
          Jobc = OB_Js(i,bi,bj)
          IF ( Jobc.NE.OB_indexNone ) THEN
           vFld(i,Jobc+1,bi,bj) = OBSvice(i,bi,bj)
     &                          *seaiceMaskV(i,Jobc+1,bi,bj)
           IF ( uvIceApplyFac.GE.0. )
     &     vFld(i,Jobc,bi,bj)   = OBSvice(i,bi,bj)
     &                          *seaiceMaskV(i,Jobc+1,bi,bj)
     &                          *uvIceApplyFac
          ENDIF
         ENDDO
        ENDIF
# endif /* ALLOW_OBCS_SOUTH */

C     Set model variables to OB values on East/West Boundaries
# ifdef ALLOW_OBCS_EAST
        IF ( tileHasOBE(bi,bj) ) THEN
C     Eastern boundary
         DO j=1-OLy,sNy+OLy
          Iobc = OB_Ie(j,bi,bj)
          IF ( Iobc.NE.OB_indexNone ) THEN
           uFld(Iobc,j,bi,bj)   = OBEuice(j,bi,bj)
     &                          *seaiceMaskU(Iobc,j,bi,bj)
           IF ( uvIceApplyFac.GE.0. )
     &     uFld(Iobc+1,j,bi,bj) = OBEuice(j,bi,bj)
     &                          *seaiceMaskU(Iobc,j,bi,bj)
     &                          *uvIceApplyFac
          ENDIF
         ENDDO
        ENDIF
# endif /* ALLOW_OBCS_EAST */

# ifdef ALLOW_OBCS_WEST
        IF ( tileHasOBW(bi,bj) ) THEN
C     Western boundary
         DO j=1-OLy,sNy+OLy
          Iobc = OB_Iw(j,bi,bj)
          IF ( Iobc.NE.OB_indexNone ) THEN
           uFld(Iobc+1,j,bi,bj) = OBWuice(j,bi,bj)
     &                          *seaiceMaskU(Iobc+1,j,bi,bj)
           IF ( uvIceApplyFac.GE.0. )
     &     uFld(Iobc,j,bi,bj)   = OBWuice(j,bi,bj)
     &                          *seaiceMaskU(Iobc+1,j,bi,bj)
     &                          *uvIceApplyFac
          ENDIF
         ENDDO
        ENDIF
# endif /* ALLOW_OBCS_WEST */

       ENDDO
      ENDDO

      CALL EXCH_UV_XY_RL( uFld, vFld,.TRUE.,myThid)

#endif /* ALLOW_SEAICE and SEAICE_CGRID and not OBCS_UVICE_OLD */

      RETURN
      END
