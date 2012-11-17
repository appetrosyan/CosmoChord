module CalcLike
 use CMB_Cls
 use cmbtypes
 use Random
 use settings
 use ParamDef
 use DataLikelihoodList
 use likelihood
 implicit none

 real(mcp) :: Temperature  = 1

 integer :: power_changes=0, slow_changes=0
 
 logical changeMask(num_params)
 logical SlowChanged, PowerChanged

contains

  function GenericLikelihoodFunction(Params) 
    type(ParamSet)  Params 
    real(mcp) :: GenericLikelihoodFunction
    real(mcp), allocatable, save :: covInv(:,:)
    real(mcp) X(num_params_used)
    
    if (test_likelihood) then
        if (.not. allocated(covInv)) then
         allocate(covInv(num_params_used,num_params_used))
         covInv = propose_matrix
         call Matrix_Inverse(covInv)
        end if
        X = Params%P(params_used) - scales%Center(params_used)
        GenericLikelihoodFunction= dot_product(X, matmul(covInv, X))/2
    else
        
   !Used when you want to plug in your own CMB-independent likelihood function:
   !set generic_mcmc=.true. in settings.f90, then write function here returning -Ln(Likelihood)
   !Parameter array is Params%P
    GenericLikelihoodFunction = LogZero 
    call MpiStop('GenericLikelihoodFunction: need to write this function!')
    end if

  end function GenericLikelihoodFunction

  
  function TestHardPriors(CMB, Info) 
    real(mcp) TestHardPriors
    Type (CMBParams) CMB
    Type(ParamSetInfo) Info

    TestHardPriors = logZero
 
    if (.not. generic_mcmc) then
     if (CMB%H0 < H0_min .or. CMB%H0 > H0_max) return
     if (CMB%zre < Use_min_zre) return

    end if
    TestHardPriors = 0
 
  end function TestHardPriors

  function GetLogLike(Params) !Get -Ln(Likelihood) for chains
    type(ParamSet)  Params 
    Type (CMBParams) CMB
    real(mcp) GetLogLike
    logical, save:: first=.true.

    if (any(Params%P > Scales%PMax) .or. any(Params%P < Scales%PMin)) then
       GetLogLike = logZero
       return
    end if

    if (generic_mcmc .or. test_likelihood) then
        GetLogLike = GenericLikelihoodFunction(Params) 
        if (GetLogLike /= LogZero) GetLogLike = GetLogLike + getLogPriors(Params%P)
        if (GetLogLike /= LogZero) GetLogLike = GetLogLike/Temperature
    else
      call ParamsToCMBParams(Params%P,CMB)
      GetLogLike  = TestHardPriors(CMB, Params%Info)
      if (GetLogLike == logZero) return
      if (first) then
           changeMask = .true.
           first = .false.
      else
           changeMask = Params%Info%lastParamArray/=Params%P
      end if

     if (CalculateRequiredTheoryChanges(CMB, Params)) then
      GetLogLike = GetLogLikeWithTheorySet(CMB, Params)
     else
       GetLogLike = logZero
     end if

     if (GetLogLike/=logZero) Params%Info%lastParamArray = Params%P
    end if

    if (Feedback>2 .and. GetLogLike/=LogZero) &
      call DataLikelihoods%WriteLikelihoodContribs(stdout, Params%Info%likelihoods)

  end function GetLogLike

  function GetLogLikePost(CMB, P, Info)
  !for importance sampling where theory may be pre-stored
    real(mcp) GetLogLikePost
    Type (CMBParams) CMB
    Type(ParamSetInfo) Info
    real(mcp) P(num_params)
    
    GetLogLikePost=logZero
   
    !need to init background correctly if new BAO etc

  end function GetLogLikePost
  
  function getLogPriors(P) result(logLike)
  integer i
  real(mcp), intent(in) :: P(num_params)
  real(mcp) logLike
  
  logLike=0
  do i=1,num_params
        if (Scales%PWidth(i)/=0 .and. GaussPriors%std(i)/=0) then
          logLike = logLike + ((P(i)-GaussPriors%mean(i))/GaussPriors%std(i))**2
        end if
  end do
  logLike=logLike/2

  end function getLogPriors
  
  logical function CalculateRequiredTheoryChanges(CMB, Params)
    type(ParamSet)  Params 
    type (CMBParams) CMB
    integer error

     SlowChanged = any(changeMask(1:num_hard))
     PowerChanged = any(changeMask(index_initpower:index_initpower+num_initpower-1))
     error=0
     if (Use_CMB .or. Use_LSS) then
         if (SlowChanged) then
           slow_changes = slow_changes + 1
           call GetNewTransferData(CMB, Params%Info, error)
         end if
         if ((SlowChanged .or. PowerChanged) .and. error==0) then
             if (.not. SlowChanged) power_changes = power_changes  + 1
             call GetNewPowerData(CMB, Params%Info, error)
         end if
     else
         if (SlowChanged) call GetNewBackgroundData(CMB, Params%Info, error)
     end if
   CalculateRequiredTheoryChanges = error==0

  end function CalculateRequiredTheoryChanges

  
  function GetLogLikeWithTheorySet(CMB, Params) result(logLike)
    real(mcp) logLike
    Type (CMBParams) CMB
    Type(ParamSet) Params
    integer error
    real(mcp) itemLike
    Class(DataLikelihood), pointer :: like
    integer i
    logical backgroundSet
    
    backgroundSet = slowChanged 
    logLike = logZero
    do i= 1, DataLikelihoods%count
     like => DataLikelihoods%Item(i)
     if (any(like%dependent_params .and. changeMask )) then
          if (like%needs_background_functions .and. .not. backgroundSet) then
              call SetTheoryForBackground(CMB)
              backgroundSet = .true.
          end if
          itemLike = like%LogLike(CMB, Params%Info%Theory)
          if (itemLike == logZero) return
          Params%Info%Likelihoods(i) = itemLike
     end if
    end do
    logLike = sum(Params%Info%likelihoods(1:DataLikelihoods%Count))
    logLike = logLike + getLogPriors(Params%P)
    logLike = logLike/Temperature

  end function GetLogLikeWithTheorySet


end module CalcLike
