using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using {cc}

#This script is a template for creating purchasable items in the game. 
#It is a parent class for all purchasable items and contains all the necessary methods and properties for a purchasable item.
#It inherits from the Detailable, Hostable,  SuperInaugurable, and Rebirthable interfaces.
#The following are the most important properties and methods:
# - Initialize method -> initializes the item and calls the parent class's Initialize method through the super keyword
# - Host method -> runs async after the item is bought
# - OnBought method -> runs after the item is bought
# - OnGrantInterval method -> grants the player money on an interval

# - Unlock method -> unlocks the item
# - UnlockDependents method -> unlocks all dependents of the item
# - TestAndCommitPurchase method -> checks if the player has enough money along with other requirements before purchasing



# - AwaitAttemptedPurchase method -> awaits the player to enter the purchase zone
# - HideProps method -> hides the props associated with the item
# - ShowProps method -> shows the props associated with the item


purchaseable<public>:=class<abstract>(Detailable, Hostable, SuperInaugurable, Rebirthable, SubHostable, IntegralFX, Gated, StringReturnables):
    var ID <public> : string = ""
    var OnInitalized <public> : event() = event(){}
    var OnInitalizedChild <public> : event() = event(){}
    var Owner <public> : base = base{}
    var Ptype <public> : PurchaseableType
    var MyIndex:int=-1
    var IsPurchased: PurchasedStatus = PurchasedStatus.NotPurchased
    var InitialStatus: Dependency = Dependency.Unlocked
    var CanLoad: logic = false

    var BegunHosting : event() = event(){}
    var UnlockEvent <public> : event() = event(){}
    var StatusChange <public> : event() = event(){}

    @editable var  Name <public>:  string = "My item name here"
    # The name of the item
    
    @editable var  Description <public>: string = "My \nmulti line \nitem description here"
    # The description of the item
    
    @editable var  Price <public>: int = {0}
    # The price of the item
    
    @editable var  ExperiencePointsToAdd  : int = {0}
    # The amount of experience points to add when the item is purchased
    
    @editable var  CurrencyToSpendID  <public>: int = {0}
    # The ID of the currency to spend when purchasing the item
    
    @editable var  CurrencyToReceiveID  <public>: int = {0}
    # The ID of the currency to receive when purchasing the item
    
    @editable var  GrantAmount <public>: int = {0}
    # The amount to grant to the player when the item is purchased
    
    @editable var  GrantInterval : ?float = option{15.0}
    # The interval at which to grant the player the grant amount
    
    @editable var  PurchaseAnimationStyle : AnimationStyle = AnimationStyle.Grouped
    # The animation style for the purchase animation
    
    @editable var  PurchaseAnimation : PAnimation = PAnimation.FadeIn
    # The specific purchase animation to use
    
    @editable var  StartAs <public> : Dependency = Dependency.Unlocked
    # The initial status of the item (locked or unlocked)

    @editable var  Accolade: accolades_device = accolades_device{}
    # The accolade associated with the item
    
    @editable var  OnUnlockCinematic : cinematic_sequence_device = cinematic_sequence_device{}
    # The cinematic sequence to play when the item is unlocked
    
    @editable var  OnPurchaseCinematic : cinematic_sequence_device = cinematic_sequence_device{}
    # The cinematic sequence to play when the item is purchased
    
    @editable var  BypassZone <public> : logic = {false}
    # Whether to bypass the purchase zone when buying the item

    @editable var UsingLinkedProps <public> : logic = {false}
    # Whether the item uses linked props 
    
    @editable var  UnlockTheseItems : []purchase_set = array{}
    # The items that should be unlocked when this item is purchased
    
    @editable var  PropsToInitialize : []creative_prop = array{}
    # The props to initialize when the item is initialized
    
    @editable var  PropsToShow : []creative_prop = array{}
    # Props that have been hidden previously by the HideProps method that you would like to now show.
    
    @editable var  PropsToHide : []creative_prop = array{}
    # The props to hide when the item is bought

    @editable var TempTogglePropsWhenEnough : []creative_prop = array{}
    # Shows these props when the player has enough money to purchase the item  [the player doesnt need to actually purchase the item]

    @editable var TempTogglePropsWhenNotEnough : []creative_prop = array{}
    # Hides these props when the player does not have enough money to purchase the item  [the player doesnt need to actually purchase the item]
    
    @editable var  HudConfig : hud_main = hud_main{}
    # The HUD configuration for the item

    @editable var BillboardConfig : billboard_main = billboard_main{}
    # The billboard configuration for the item
    
    @editable var  ConditionsToBuy : condition = condition{}
    # The conditions that must be met in order to buy the item
    
    @editable var  Purchase_Zone : unique_buy_zone = unique_buy_zone{}
    # The purchase zone associated with the item
    
    @editable var  VFX : vfx_main = vfx_main{}
    # The visual effects for the item

    @editable var SFX : sfx_main = sfx_main{}
    # The sound effects for the item
    


    #*********************#
    #  Interface methods  #
    #*********************#    

    OnRebirth<override>():void=
        if(InitialStatus = Dependency.Unlocked){Unlock()}
        if(InitialStatus = Dependency.Locked){Lock()}

        if:
            IsPurchased = PurchasedStatus.Purchased
        then:
            InitializeChildren(Owner, MyIndex)
    

    #Prints the item's details
    Detail<override>(Type:string)<transacts>:void=
        GlobalSuperlog("==[{Type}]==")

    #Initializes the item
    Initialize<override>(Hostess:base, I:int):void=
        GlobalSuperlog("Initializing {Name}...")
        VFX.OnBegin(-1)
        SFX.OnBegin(-1)
        BillboardConfig.OnBegin(-1)
        BillboardConfig.Initialize(Self)
        HudConfig.Initialize(Self)
        HideProps(PropsToInitialize)
        SetGranularDist()
        set InitialStatus = StartAs
        set MyIndex = I
        set Owner = Hostess
        spawn{SubHost()}
        set Purchase_Zone.Origin = Purchase_Zone.Zone.GetTransform().Translation
        spawn{Purchase_Zone.AwaitUnlock(Self)}
        
        if:
            X := CreateID[10]
            set ID = X
        else:
            GlobalSuperlog("Couldnt make ID for: {Name};")

        if:
            StartAs = Dependency.Unlocked
        then:
            InitializeChildren(Hostess, I)
        else:
            GlobalSuperlog("{Name} is locked. Not initializing children... --->> Awaiting until unlocked.")
            HidePropsWNE()


    SetGranularDist():void=
        if:
            UsingLinkedProps?
        then:
            set GranualarDist = -10000.0
        
        
    InitializeChildren(Hostess:base, I:int):void=
        set CanLoad = true
        set Owner = Hostess
        Purchase_Zone.Initialize(Hostess, false)
        InitializeFX()
        BillboardConfig.Instantiate()
        spawn{AwaitAttemptedPurchase(Purchase_Zone, Hostess)}
        OnInitalized.Signal()




    
    #Runs after the item is bought
    #This method is meant to be overridden by the child class
    #It runs after the item is bought and is meant to be used for any async code that needs to run after the item is bought
    Host<override>()<suspends>:void


    ShowPropsWNE():void=
        for{Prop:TempTogglePropsWhenNotEnough, Prop.IsValid[]}
        do. Prop.Show()

    HidePropsWNE():void=
        for{Prop:TempTogglePropsWhenNotEnough, Prop.IsValid[]}
        do. Prop.Hide()

    ShowPropsWE():void=
        for{Prop:TempTogglePropsWhenEnough, Prop.IsValid[]}
        do. Prop.Show()

    HidePropsWE():void=
        for{Prop:TempTogglePropsWhenEnough, Prop.IsValid[]}
        do. Prop.Hide()

    #Runs before the item is bought. (In this particular instance it also cancels after the item is bought)
    SubHost<override>()<suspends>:void=
        race:
            block: 
                # Wait for the BegunHosting event to be signaled; meaning the prop was successfully purchased
                BegunHosting.Await()

                # Hide the props that should be hidden when the player doesn't have enough money; this is done overtime and disables collision
                ShowPropsWNE
                return
            block:
                loop:
                    # Wait for the MoneyGranted event to be signaled and get the player and current currency value
                    Value := Owner.MoneyGranted.Await();
                    PreventInf();
                    if:
                        Player := Value(0)
                        CurrentValue := GetStats[Player].AssociatedCurrencies[CurrencyToSpendID]
                        # Check if the player has enough money to purchase the item
                        CurrentValue >= Price
                    then:
                        # Insantly shows the props that should be shown when the player has enough money
                        ShowPropsWE() 
                        HidePropsWNE()
                    else:
                        # Insantly shows the props that should be shown when the player doesn't have enough money
                        ShowPropsWNE()
                        HidePropsWE()
                            
                        

                    
    #Intergral FX System methods
    InitalizeVisuals<override>():void=
        VFX.Initialize(Owner)

    InitalizeAudibles<override>():void=
        SFX.Initialize(Owner)

    InitializeFX<override>():void=
        VFX.Initialize(Owner)  
    
    GetStringParams<override>()<transacts>:[string]string=
        var default : [string]string =  map
        {
            "[Name]"=>Name, 
            "[ID]"=>ID, 
            "[Description]"=>Description, 
            "[Price]"=>"{Price}", 
            "[CurrencyToSpendID]"=>"{CurrencyToSpendID}", 
            "[CurrencyToReceiveID]"=>"{CurrencyToReceiveID}", 
            "[GrantAmount]"=>"{GrantAmount}", 
            "[Ptype]"=>"{Ptype.ToStr()}", 
            "[IsPurchased]"=>"{IsPurchased.ToStr()}"
        }
        if:
            MaybeGrantInterval := GrantInterval?
            set default["[GrantInterval]"] = "{MaybeGrantInterval}"
        return default

        
    #*********************#
    #    Class methods    #
    #*********************#       
    #Unlocks all dependents of the item
    #Returns the number of failures and a boolean indicating if there were any failures
    #The failures are the number of dependents that failed to unlock
    #The boolean indicates if any dependents failed to unlock
    UnlockDependents(Base:base):tuple(int, logic)=
        #Not using the decides / transacts effects so we dont rollback all the other unlocks that were successful.
        var anyfailures:logic=false
        var failures:int=0
        for:
            I -> ItemSet:UnlockTheseItems
        do:
            case(ItemSet.Type):
                PurchaseableType.Undefined =>
                    GlobalSuperlog("Type for 'UnlockTheseItems[{I}]' is undefined")
                PurchaseableType.BasicProp =>
                    if:
                        Basic_Prop := Base.BasicProps[ItemSet.Index]
                    then:
                        Basic_Prop.Unlock()  
                    else:
                        set anyfailures = true; set failures += 1
                        UnlockFailure(ItemSet.Index, "BasicProp")
                PurchaseableType.NPCBuyable =>
                    if:
                        NPC_Buyable := Base.NPCSpawners[ItemSet.Index]
                    then:
                        NPC_Buyable.Unlock()  
                    else:
                        set anyfailures = true; set failures += 1
                        UnlockFailure(ItemSet.Index, "NPCBuyable")
                PurchaseableType.Dropper =>
                    if:
                        Dropper := Base.Droppers[ItemSet.Index]
                    then:
                        Dropper.Unlock()  
                    else:
                        set anyfailures = true; set failures += 1
                        UnlockFailure(ItemSet.Index, "Dropper")
                PurchaseableType.Conveyor =>
                    if:
                        Conveyor := Base.Conveyors[ItemSet.Index]
                    then:
                        Conveyor.Unlock()  
                    else:
                        set anyfailures = true; set failures += 1
                        UnlockFailure(ItemSet.Index, "Conveyor")
                PurchaseableType.Shootable =>
                    if:
                        Shootable := Base.Shootables[ItemSet.Index]
                    then:
                        Shootable.Unlock()  
                    else:
                        set anyfailures = true; set failures += 1
                        UnlockFailure(ItemSet.Index, "Shootable")
                PurchaseableType.Hitable =>
                    if:
                        Hitable := Base.Hitables[ItemSet.Index]
                    then:
                        Hitable.Unlock()
                    else:
                        set anyfailures = true; set failures += 1
                        UnlockFailure(ItemSet.Index, "Hitable")
                PurchaseableType.DanceFloor =>
                    if:
                        DanceFloor := Base.DanceFloors[ItemSet.Index]
                    then:
                        DanceFloor.Unlock()
                    else:
                        set anyfailures = true; set failures += 1
                        UnlockFailure(ItemSet.Index, "DanceFloor")

                PurchaseableType.Pet =>
                    if:
                        Pet := Base.Pets[ItemSet.Index]
                    then:
                        Pet.Unlock()
                    else:
                        set anyfailures = true; set failures += 1
                        UnlockFailure(ItemSet.Index, "Pet")
        (failures, anyfailures)



        
                        





    #Unlocks the item
    #If the item is locked, unlock it else fail
    #If the item is unlocked, play the unlock cinematic and unlock all dependents
    Unlock<override>():void=
        #if the item is locked, unlock it else fail
        if:
            StartAs = Dependency.Locked
        then:
            set StartAs = Dependency.Unlocked
            StatusChange.Signal()
            UnlockEvent.Signal()
            InitializeChildren(Owner, MyIndex)
        else:
            return

        
        #If the item is unlocked, play the unlock cinematic and unlock all dependents
        for:
            Player:Owner.Players
        do:
            OnUnlockCinematic.Play(Player)
        return 

    Lock<override>():void=
        #if the item is locked, unlock it else fail
        if:
            StartAs = Dependency.Unlocked
        then:
            set StartAs = Dependency.Locked
            StatusChange.Signal()
        else:
            return


    #Cheks if the player has enough money to purchase the item and other requirements are met before committing the purchase.
    #If the player has enough money, the item is purchased, purchase zone is disabled and the player's stats are updated
    #If the player does not have enough money, the purchase fails
    #If the item is locked, the purchase fails
    TestAndCommitPurchase(Agent:agent)<decides><transacts>:void=
        GlobalSuperlog("== Attempting Purchase == ")
        #Gets the player's stats
        Player:=player[Agent]
        Stats := GetStats[Player]
        #Gets the player's money associated with the CurrencyToSpendID
        
        AssociatedCurrencies := Stats.AssociatedCurrencies
        #Gets the player's money associated with the CurrencyToReceiveID
        MoneyAssociatedWith_ToSpendID := AssociatedCurrencies[CurrencyToSpendID]
       
        
        
        #Checks if the player has enough money to purchase the item
        MoneyAssociatedWith_ToSpendID >= Price

        MeetsConditions[ConditionsToBuy, Player, CurrencyToSpendID]

        #Checks if the item is unlocked
        StartAs = Dependency.Unlocked

        #If the player has enough money, the item is purchased, purchase zone is disabled and the player's stats are updated
        RemoveMoney(Owner, Player, CurrencyToSpendID, Price)

        #Adds money to the player's CoinDex for the CurrencyToReceiveID
        MoneyAssocatiedWith_ToReceiveID := AssociatedCurrencies[CurrencyToReceiveID]
        
        return
    
    
    #Grants the player money and experience points on an interval
    OnGrantInterval(Agent:agent)<suspends>:void=
        GlobalSuperlog("-Granting Money on Interval")
        if(GA := GrantInterval?){if(Owner.MoneyLeague.Update[Owner, CurrencyToReceiveID, GrantAmount, GA]){GlobalSuperlog("Updated MoneyLeague using: {Name}")}}
        loop:
            if:
                GrantInterval? >= 0.0
                Interval := GrantInterval?
                Player : player = player[Agent]
                Stats := GetStats[Player]
                MoneyToReceive := Stats.AssociatedCurrencies[CurrencyToReceiveID]
                IsPurchased = PurchasedStatus.Purchased
            then:
                GrantMoney(Owner, Player, CurrencyToReceiveID, GrantAmount, BypassZone)   
                Sleep(Interval+0.0)
                
            else{Print("No interval set for: {Name}; or interval is less than 0.0; returning..."); return}
                    
        

        
            
        
    #Defines the prop's Z coord for every PAnimation type: which is where it will be held stationary.
    var GranualarDist: float = 1500.0


   
    #Awaiting the player to enter the purchase zone. 
    AwaitAttemptedPurchase(PZ:unique_buy_zone, Hostess:base)<suspends>:void=
        loop:
            PreventInf();
            Agent := Purchase_Zone.PlayerEntersEvent.Await()
            if:
                TestAndCommitPurchase[Agent]
                Player := player[Agent]
                IsPurchased = PurchasedStatus.NotPurchased
            then:
                GrantMoney(Owner, Player, CurrencyToReceiveID, GrantAmount, BypassZone)
                OnBought(Player)
                FirstBought(Player)

            else{Purchase_Zone.Enable();  HudConfig.OnFail(Owner); Print("Failed to purchase {Name}");}

    #Runs after the item is bought
    OnBought<public>(Agent:agent):void=
        #If the player has enough money, the item is purchased, purchase zone is disabled and the player's stats are updated
        if:
            Player := player[Agent]
            CanLoad?
        then:
            set CanLoad = false
            UpdateXP(Player, ExperiencePointsToAdd)
            Accolade.Award(Player)
            GrantXP(Owner, Player, ExperiencePointsToAdd)
            set IsPurchased = PurchasedStatus.Purchased
            HideProps(PropsToHide)
            
            Purchase_Zone.OnSuccess(Player, true)
            Purchase_Zone.Disable()
            
            Result := UnlockDependents(Owner)
            if(Result(1)?){Print("When Unlocking all dependents, ({Result(0)}) failed to unlock")}
            spawn{OnGrantInterval(Agent)}
            spawn{ShowProps(PropsToInitialize+PropsToShow)}
            spawn{Host()};  BegunHosting.Signal()
            VFX.OnEvent(Player)
            SFX.OnEvent(Player)
            
            
            
            UpdateAssociatedUnlocks(Player, Ptype, MyIndex)
    FirstBought(Agent:agent):void=
        if:
            Player := player[Agent]
        then:
            OnPurchaseCinematic.Play(Player)
            HudConfig.OnSuccess(Owner)
            Print("|==|----[{Name} ]----|==|")
            Print("|==|----[ Successfully Purchased ]----|==|")





    #Defines the arguements for every PAnimation type
    var PropAlterations:int=0

    #Hides the props associated with the item
    #The props are then moved to a location below the player with a specified animation speed
    HideProps(PropsToAlter:[]creative_prop)<transacts>:void=
        set PropAlterations -= 1
        for(I -> Prop:PropsToAlter){
        if:
                Prop.IsValid[]
        then:
            Prop.Hide()
            PT := Prop.GetTransform().Translation
            PR := Prop.GetTransform().Rotation
            PL := vector3{X:=PT.X, Y:=PT.Y, Z:=PT.Z-GranualarDist}
                if(Prop.TeleportTo[PL, PR]){}
        }
        return
    #Shows the props associated with the item
    ShowProps(PropsToAlter:[]creative_prop)<suspends>:void=
        set PropAlterations += 1
        for(I -> Prop:PropsToAlter)
        {
            if:
                Prop.IsValid[]
            then:
                Prop.Show()
                PT := Prop.GetTransform().Translation
                PR := Prop.GetTransform().Rotation
                PL := vector3{X:=PT.X, Y:=PT.Y, Z:=PT.Z+GranualarDist}

                #Props are moved as if they were one solid object (Grouped)
                #This results in a style similar to a whole object being placed.


                case(PurchaseAnimationStyle):
                    AnimationStyle.Grouped =>
                        spawn{SpawnedMovement(Prop, PL, PR, GetSpeed(PurchaseAnimation))}
                    
                    #Does the same as the grouped style but for each prop individually one by one 
                    #This results in a style similar to legos being built

                    AnimationStyle.LegoLike =>
                        Prop.MoveTo(PL, PR, GetSpeed(PurchaseAnimation)/1.75)

                    AnimationStyle.LegoLike5x =>
                        Prop.MoveTo(PL, PR, GetSpeed(PurchaseAnimation)/7.0)

                        
        }
        return
    GetSpeed(Anim:PAnimation):float=
        case(Anim):
            PAnimation.SlowFadeIn => 
                return 1.25
            PAnimation.FadeIn =>
                return 1.0
            PAnimation.FastFadeIn =>
                return 0.75

    SpawnedMovement(Prop:creative_prop, PL:vector3, PR:rotation, Speed:float)<suspends>:void=
        Prop.MoveTo(PL, PR, Speed)
    
        

#Example of how to create a purchasable item using the purchaseable superclass as a parent class. 
#This class is a template for creating purchasable items in the game.
#It inherits from the purchaseable class and contains all the necessary methods and properties for a purchasable item.


#It contains the following properties and methods:
# - Initialize method -> initializes the item and calls the parent class's Initialize method through the super keyword
# - Host method -> runs after the item is bought
basic_prop_buyable<public>:=class<concrete><final>(purchaseable):

    var Ptype <override> :  PurchaseableType = PurchaseableType.BasicProp

    #Initializes the item
    Initialize<override>(Hostess:base, I:int):void=
        #Calls the parent class's Initialize method and waits for it to finish
        (super:)Initialize(Hostess, I)
        
        #Lists out all the properties of the item
        Detail("BasicPropBuyable")


    #Runs after the item is bought
    Host<override>()<suspends>:void=
        #My async code here
        loop:
            Sleep(Inf);


#Example of how to create a second superclass for purchasable items using the purchaseable superclass as a parent class.
#This one is a purchaseable where the fx should react off of the child class' events.
fxpurchaseable<public>:=class<abstract>(purchaseable, ExpandedFX):
    
    @editable var FXMain  <public> :  fx_main = fx_main{}

    TrigEvent : event() = event(){}
    var FirstPlayerOnTeam: ?player = false


    #FX System methods from the ExpandedFX interface

    InitalizeVisuals<override>():void=
        VFX.Initialize(Owner)
        FXMain.EventBasedVFX.Initialize(Owner)

    InitalizeAudibles<override>():void=
        SFX.Initialize(Owner)
        FXMain.EventBasedSFX.Initialize(Owner)

    InitializeFX<override>():void=
        VFX.Initialize(Owner)  
        FXMain.EventBasedVFX.Initialize(Owner)
        FXMain.EventBasedSFX.Initialize(Owner)
        set FirstPlayerOnTeam = Owner.FindFirstPlayerOnTeam()

    PlayFX<override>():void=
        if:
            Player := FirstPlayerOnTeam?
        then:
            VFX.OnEvent(Player)
            SFX.OnEvent(Player)
            FXMain.EventBasedVFX.OnEvent(Player)
            FXMain.EventBasedSFX.OnEvent(Player)

    StopFX<override>():void=
        VFX.EndEvent()
        SFX.EndEvent()
        FXMain.EventBasedVFX.EndEvent()
        FXMain.EventBasedSFX.EndEvent()

    PlayVisuals<override>():void=
        if:
            Player := FirstPlayerOnTeam?
        then:
            VFX.OnEvent(Player)
            FXMain.EventBasedVFX.OnEvent(Player)

    StopVisuals<override>():void=
        VFX.EndEvent()
        FXMain.EventBasedVFX.EndEvent()


    PlayAudibles<override>():void=
        if:
            Player := FirstPlayerOnTeam?
        then:
            SFX.OnEvent(Player)
            FXMain.EventBasedSFX.OnEvent(Player)

    StopAudibles<override>():void=
        SFX.EndEvent()
        FXMain.EventBasedSFX.EndEvent()


    OnEvent()<suspends>:void=
        TrigEvent.Signal()
        if:
            FXMain.RestartWhenActivated?
        then:
            race:
                block: 
                    Sleep(0.1)
                    AsyncPlayFX(FXMain.FXLength)
                block: 
                    TrigEvent.Await()
                    StopFX()
        else:
            race:
                block: 
                    AsyncPlayFX(FXMain.FXLength)
                block: 
                    TrigEvent.Await()
        
    #Custom class methods
    AsyncPlayFX(Time:float)<suspends>:void={PlayFX(); Sleep(Time); StopFX(); return}



        
        
        

            
    
    






            
                






        
        
        

