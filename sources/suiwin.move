module suiwin::suiwin {
    use sui::random::{Self,Random};
    use sui::event::emit;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::dynamic_object_field as dof;
 




    const EInsufficientBalance: u64 = 0;
    const EAmountNot: u64 = 1;
    const EGamegues: u64 = 2;
    const ERounds:u64 = 3;
    const EWithdrawallockORpklock:u64 = 4;
    

    const Adminadd: address = @0x82242fabebc3e6e331c3d5c6de3d34ff965671b75154ec1cb9e00aa437bbfa44;
    const GETime:u64 = 9999999;
    const MIN:u64 = 10_000_000;
    const MAX:u64 = 260_000_000_000;



    public struct GameData has key{
        id: UID,
        balance: Balance<SUI>,
        min_bet: u64,
        max_bet: u64,
        admin_address: address,
        fee_bp: u64,
    }

    public struct Game21 has key,store{
        id: UID,
        bet:u64,
        d: vector<u8>,
        p: vector<u8>,
    }

    public struct Game21_b has key,store{
        id: UID,
        b:bool,
        bet:u64,
        d: vector<u8>,
        p: vector<u8>,
    }



    public struct WLock has key{
        id: UID,
        data: u64,

    }

    public struct Outcome has copy,drop {
        gamenumber:u8,
        bonus:u64,
        coinvalue:u64,
        result:u8,
    }

    public struct Outcome21 has copy,drop {
        bet:u64,
        d: vector<u8>,
        p: vector<u8>,
        gamenum:u8,
    }

    public struct Outcome_Baccarat has copy,drop {
        bet:u64,
        winvol:u64,
        b: vector<u8>,
        p: vector<u8>,
        gnum:u8,
        result:u8,
    }

    public struct AdminCap has key ,store{ id: UID }



    fun init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));

       
        transfer::share_object(WLock {
            id: object::new(ctx),
            data:GETime,
        });



    }
    entry fun transferAdminCap(cap:AdminCap,add:address){
        transfer::public_transfer(cap, add);

    }

    public entry fun init_GameData(_: &AdminCap,coin: Coin<SUI>,ctx: &mut TxContext) {
        let game = GameData{
            id:object::new(ctx),
            balance:coin::into_balance(coin),
            min_bet: MIN,
            max_bet: MAX,
            admin_address:Adminadd,
            fee_bp: 15,
        };
        transfer::share_object(game);
    }


    public entry fun change_min_bet(_: &AdminCap,change:u64,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EWithdrawallockORpklock);
        gamedata.min_bet = change;
        wl.data = GETime;

    }
    public entry fun change_max_bet(_: &AdminCap,change:u64,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EWithdrawallockORpklock);
        gamedata.max_bet = change;
        wl.data = GETime;
    }

    public entry fun change_WL(_: &AdminCap,wl:&mut WLock,ctx: &mut TxContext){
        wl.data = tx_context::epoch(ctx);

    }
   

    public entry fun change_admin_address(_: &AdminCap,change:address,gamedata:&mut GameData){
        gamedata.admin_address = change;
    }

    public entry fun change_fee_bp(_: &AdminCap,change:u64,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EWithdrawallockORpklock);
        gamedata.fee_bp = change;
        if(gamedata.fee_bp>30){
            gamedata.fee_bp =30
        };
        wl.data = GETime;
    }


    public entry fun Withdraw_admin(_: &AdminCap,wl:&mut WLock,amount:u64,gamedata:&mut GameData,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EWithdrawallockORpklock);
        let coin_value = coin::take(&mut gamedata.balance, amount, ctx);
        transfer::public_transfer(coin_value, gamedata.admin_address);
        wl.data = GETime;
    }

    


    public entry fun up_sui(gamedata:&mut GameData,coin_value: Coin<SUI>){
        coin::put(&mut gamedata.balance, coin_value);
    }
//.......................................................................coinflit.....................................................................
    entry  fun game_stake(r : &Random,game_data: &mut GameData, p_guess: u8, coin_v: Coin<SUI>, ctx: &mut TxContext){

        let coin_value = coin::value(&coin_v);
        let contract_balance = balance::value(&game_data.balance);
 
        assert!(contract_balance > coin_value, EInsufficientBalance);

        assert!(coin_value >= game_data.min_bet && coin_value <= game_data.max_bet, EAmountNot);
        
        coin::put(&mut game_data.balance, coin_v);
        let mut rg = random::new_generator(r, ctx);
        let first_num =  random::generate_u8_in_range(&mut rg, 0, 1);
        let player_won = p_guess == first_num;
        let income = if (player_won) {
            let _amount = coin_value/1000u64;
            let amount = _amount * (1000u64 - game_data.fee_bp) * 2;
            
            let coin = coin::take(&mut game_data.balance, amount, ctx);
            transfer::public_transfer(coin,tx_context::sender(ctx));
            
            amount
        } else {
            0u64
        };
        emit(Outcome {
            gamenumber:0,
            bonus:income,
            coinvalue:coin_value,
            result:first_num,
        });
    }

//.......................................................................box.....................................................................


   entry  fun game_stake_box(r : &Random,game_data: &mut GameData, coin_v: Coin<SUI>, ctx: &mut TxContext){

        let coin_value = coin::value(&coin_v);
        let contract_balance = balance::value(&game_data.balance);
 
        assert!(contract_balance > coin_value*10, EInsufficientBalance);

        assert!(coin_value >= game_data.min_bet && coin_value <= game_data.max_bet, EAmountNot);

        coin::put(&mut game_data.balance, coin_v);
        let mut rg = random::new_generator(r, ctx);
        let player_won = 90u16 > random::generate_u16_in_range(&mut rg, 0, 999);
        let income = if (player_won) {
            let amount = coin_value*10;
            let coin = coin::take(&mut game_data.balance, amount, ctx);
            transfer::public_transfer(coin,tx_context::sender(ctx));
            amount
        } else {
            0u64
        };
        emit(Outcome {
            gamenumber:1,
            bonus:income,
            coinvalue:coin_value,
            result:0,
        });
    }

//...........................................dice......................................................................................

    entry  fun game_stake_dice(r : &Random,game_data: &mut GameData, p_guess: u8, coin_v: Coin<SUI>, ctx: &mut TxContext){

        let coin_value = coin::value(&coin_v);
        let contract_balance = balance::value(&game_data.balance);
 
        assert!(contract_balance > coin_value*6, EInsufficientBalance);
        assert!(coin_value >= game_data.min_bet && coin_value <= game_data.max_bet, EAmountNot);
        assert!(p_guess < 63, EGamegues);

        coin::put(&mut game_data.balance, coin_v);
        let mut rg = random::new_generator(r, ctx);
        let value = random::generate_u8_in_range(&mut rg, 0, 5);
        let result = std::u8::pow(2,value);
        let player_won = p_guess & result;
        let income = if (player_won > 0) {
            let mul = count_ones(p_guess) as u64;
            let multiple = 60 / mul;
            let _amount = coin_value/10000u64;
            let amount = _amount * (1000u64 - game_data.fee_bp) * multiple;
            
            let coin = coin::take(&mut game_data.balance, amount, ctx);
            transfer::public_transfer(coin,tx_context::sender(ctx));
            
            amount
        } else {
            0u64
        };

        emit(Outcome {
            gamenumber:2,
            bonus:income,
            coinvalue:coin_value,
            result:value,
        });
    }

    fun count_ones(nn: u8):(u8) {
        let mut count = 0;
        let mut num = nn;
        while (num != 0) {
            count = count + (num % 2);
            num = num / 2;
        };
        count
    }



//.......................................................................Baccarat.....................................................................
    entry  fun game_stake_Baccarat(r : &Random,game_data: &mut GameData, p_guess: u8, coin_v: Coin<SUI>, ctx: &mut TxContext){

        let coin_value = coin::value(&coin_v);
        let contract_balance = balance::value(&game_data.balance);
 
        assert!(contract_balance > coin_value, EInsufficientBalance);

        assert!(coin_value >= game_data.min_bet && coin_value <= game_data.max_bet, EAmountNot);
        assert!(p_guess < 3, ERounds);
        coin::put(&mut game_data.balance, coin_v);
        let bankerCS = baccarat_dealing_cards(r,ctx);
        let playerCS = baccarat_dealing_cards(r,ctx);
        let result_num =  baccarat_compare_cards(&bankerCS,&playerCS);
        
        let player_won = p_guess == result_num;
        let income = if (player_won) {
            if(result_num == 2){
                let amount = coin_value * 2;
                let coin = coin::take(&mut game_data.balance, amount, ctx);
                transfer::public_transfer(coin,tx_context::sender(ctx));
                amount
            }else if(result_num == 1){
                let _amount = coin_value/100u64;
                let amount = _amount * 195;
                
                let coin = coin::take(&mut game_data.balance, amount, ctx);
                transfer::public_transfer(coin,tx_context::sender(ctx));
                amount
            }else{
                let amount = coin_value * 9;
                let coin = coin::take(&mut game_data.balance, amount, ctx);
                transfer::public_transfer(coin,tx_context::sender(ctx));
                amount
            }
            
        } else {
            if(result_num==0){
                let amount = coin_value;
                let coin = coin::take(&mut game_data.balance, amount, ctx);
                transfer::public_transfer(coin,tx_context::sender(ctx));
                amount
            }else{
                0u64
            }
        };

        emit(Outcome_Baccarat{
            bet:coin_value,
            winvol:income,
            b: bankerCS,
            p: playerCS,
            gnum:p_guess,
            result:result_num,
        });
    }



    fun baccarat_dealing_cards(r : &Random,ctx: &mut TxContext):(vector<u8>){

        let mut rg = random::new_generator(r, ctx);
        let mut cardlen = 0;
        let mut caeds = vector::empty<u8>();
        while(cardlen < 3){
            let mut card = random::generate_u8_in_range(&mut rg, 1, 13);
            if(card>9){
                card = 0;
            };
            vector::push_back(&mut caeds, card);
            cardlen = cardlen+1;
        };
        caeds
    }



    fun baccarat_compare_cards(b: &vector<u8>, p: &vector<u8>): u8 {
        let bcard1 = *vector::borrow(b, 0);
        let bcard2 = *vector::borrow(b, 1);
        let bcard3 = *vector::borrow(b, 2);
        let pcard1 = *vector::borrow(p, 0);
        let pcard2 = *vector::borrow(p, 1);
        let pcard3 = *vector::borrow(p, 2);
        
        let b2 = (bcard1 + bcard2) % 10;
        let p2 = (pcard1 + pcard2) % 10;
        let b3 = (bcard1 + bcard2 + bcard3) % 10;
        let p3 = (pcard1 + pcard2 + pcard3) % 10;

      
        if (b2 == 8 || b2 == 9 || p2 == 8 || p2 == 9) {
            if (b2 > p2) {
                return 1
            } else if (b2 < p2) {
                return 2
            } else {
                return 0
            }
        };

      
        if (p2 > 5) {
            if (b2 > 5) {
                if (b2 > p2) {
                    return 1
                } else if (b2 < p2) {
                    return 2
                } else {
                    return 0
                }
            } else {
                if (b3 > p2) {
                    return 1
                } else if (b3 < p2) {
                    return 2
                } else {
                    return 0
                }
            }
        } else if (b2 > 6) {
            if (b2 > p3) {
                return 1
            } else if (b2 < p3) {
                return 2
            } else {
                return 0
            }
        } else {
            if (b2 < 3 || (b2 == 3 && pcard3 != 8)
                || (b2 == 4 && pcard3 != 8 && pcard3 != 9 && pcard3 != 0 && pcard3 != 1)
                || (b2 == 5 && (pcard3 == 4 || pcard3 == 5 || pcard3 == 6 || pcard3 == 7))
                || (b2 == 6 && (pcard3 == 6 || pcard3 == 7))
            ) {
                if (b3 > p3) {
                    return 1
                } else if (b3 < p3) {
                    return 2
                } else {
                    return 0
                }
            } else {
                if (b2 > p3) {
                    return 1
                } else if (b2 < p3) {
                    return 2
                } else {
                    return 0
                }
            }
        };

        // Default return value
        3
    }


























//.....................................................21..........................................................

    entry  fun game_stake_21_join(r : &Random,game_data: &mut GameData, coin_v: Coin<SUI>,ctx: &mut TxContext){//0加入游戏state:u8,
        let coin_value = coin::value(&coin_v);
        let contract_balance = balance::value(&game_data.balance);
        assert!(contract_balance > coin_value*2, EInsufficientBalance);
        assert!(coin_value >= game_data.min_bet && coin_value <= game_data.max_bet, EAmountNot);
        coin::put(&mut game_data.balance, coin_v);
        let mut rg = random::new_generator(r, ctx);
        let card1 = random::generate_u8_in_range(&mut rg, 1, 13);
        let card2 = random::generate_u8_in_range(&mut rg, 1, 13); //庄家的牌
        let card3 = random::generate_u8_in_range(&mut rg, 1, 13);
        let mut dcaeds = vector::empty<u8>();
        let mut pcaeds = vector::empty<u8>();
        vector::push_back(&mut dcaeds, card2);
        vector::push_back(&mut pcaeds, card1);
        vector::push_back(&mut pcaeds, card3);
        let vol = calculate_hand_value(&pcaeds);
        let obid = object::new(ctx);
        if((vol == 21)){
            let game = Game21_b{
                id: obid,
                b:true,
                bet:coin_value,
                d: dcaeds,
                p: pcaeds,
            };
            let oid = object::id(&game);
            dof::add(&mut game_data.id,oid, game); 
            let winvol = coin_value + coin_value*3/2;
            let wincoin = coin::take(&mut game_data.balance, winvol, ctx);
            transfer::public_transfer(wincoin,tx_context::sender(ctx));
        }else{
            let game = Game21{
                id: obid,
                bet:coin_value,
                d: dcaeds,
                p: pcaeds,
            };
            dof::add(&mut game_data.id,tx_context::sender(ctx), game);
        };
        emit(Outcome21 {
            bet:coin_value,
            d: dcaeds,
            p: pcaeds,
            gamenum:0,
        });

    }

    entry  fun game_stake_21_double(r : &Random,game_data: &mut GameData, coin_v: Coin<SUI>,ctx: &mut TxContext){
        let Game21 {
            id,
            bet,
            mut d,
            mut p,
        }  = dof::remove(&mut game_data.id,tx_context::sender(ctx));
        object::delete(id);
        let coin_value = coin::value(&coin_v);
        let len = vector::length(&p);
        assert!(coin_value >= bet, EAmountNot);
        assert!(len == 2, ERounds);
        coin::put(&mut game_data.balance, coin_v);
        let mut rg = random::new_generator(r, ctx);
        let card = random::generate_u8_in_range(&mut rg, 1, 13);
        vector::push_back(&mut p, card);
        let vol = calculate_hand_value(&p);
        if(vol < 22){
            let resultb = compared(r,&mut d,vol,ctx); 
            if(resultb ==1 ){
                let winvol = (coin_value + bet)*2;
                let wincoin = coin::take(&mut game_data.balance, winvol, ctx);
                transfer::public_transfer(wincoin,tx_context::sender(ctx));
            }else if(resultb ==2){
                let winvol = coin_value + bet;
                let wincoin = coin::take(&mut game_data.balance, winvol, ctx);
                transfer::public_transfer(wincoin,tx_context::sender(ctx));
            };
        };
        emit(Outcome21 {
            bet:bet,
            d: d,
            p: p,
            gamenum:1,
        });
    }

    entry  fun game_stake_21_hit(r : &Random,game_data: &mut GameData, ctx: &mut TxContext){
        let Game21 {
            id,
            bet,
            d,
            mut p,
        }  = dof::remove(&mut game_data.id,tx_context::sender(ctx));
        object::delete(id); 
        let mut rg = random::new_generator(r, ctx);
        let card = random::generate_u8_in_range(&mut rg, 1, 13);
        vector::push_back(&mut p, card);
        let vol = calculate_hand_value(&p);
        if(vol < 22){
            let game = Game21{
                id: object::new(ctx),
                bet:bet,
                d: d,
                p: p,
            };
            dof::add(&mut game_data.id,tx_context::sender(ctx), game);
        };
        emit(Outcome21 {
            bet:bet,
            d: d,
            p: p,
            gamenum:2,
        });
    }




    entry  fun game_stake_21_stand(r : &Random,game_data: &mut GameData, ctx: &mut TxContext){
        let Game21 {
            id,
            bet,
            mut d,
            p,
        }  =  dof::remove(&mut game_data.id,tx_context::sender(ctx));
        object::delete(id);
        let len = vector::length(&p);
        let mut vol = calculate_hand_value(&p);
    
        if(len >=5){
            vol =21;
 
        };
        let resultb = compared(r,&mut d,vol,ctx);
        if(resultb ==1){
            let winvol = bet*2;

            let wincoin = coin::take(&mut game_data.balance, winvol, ctx);
            transfer::public_transfer(wincoin,tx_context::sender(ctx));
        }else if(resultb ==2){
            let winvol = bet;
            let wincoin = coin::take(&mut game_data.balance, winvol, ctx);
            transfer::public_transfer(wincoin,tx_context::sender(ctx));
        };
        emit(Outcome21 {
            bet:bet,
            d: d,
            p: p,
            gamenum:4,
        });
    }


    entry fun delete_Game21_b(id:ID,game_data: &mut GameData){
        let Game21_b {
            id,
            b,
            bet:_,
            d:_,
            p:_,
        }  = dof::remove(&mut game_data.id,id);
        assert!(b, ERounds);
        object::delete(id);
    }


    fun calculate_hand_value(cards:&vector<u8>):(u8){
        let mut total_value = 0;
        let mut ace_count = 0;

 
        let card_count = vector::length(cards);
        let mut i = 0;
        while (i < card_count) {
            let card = vector::borrow(cards, i);
            let card_value = card_value(*card);
            total_value = total_value+card_value;
            if(card == 1) {
                ace_count = ace_count+1;
            };
            i =i + 1;
        };

    
        while (total_value > 21 && ace_count > 0) {
            total_value =total_value - 10;
            ace_count =ace_count - 1;
        };
        
        total_value
    }

    
    fun card_value(card: u8): u8 {
        if (card == 1) {
            11 
        } else if (card >= 11 && card <= 13) {
            10 
        } else {
            card 
        }
    }

    fun compared(r : &Random,d:&mut vector<u8>,p:u8,ctx: &mut TxContext):(u8){
        let mut dvol = 0;
        let mut rg = random::new_generator(r, ctx);
        let mut cardlen = 1;
        while(dvol < 17 && cardlen < 5){
            let card = random::generate_u8_in_range(&mut rg, 1, 13);
            vector::push_back(d, card);
            dvol = calculate_hand_value(d);
            cardlen = cardlen+1;
        };
        let len = vector::length(d);
        let mut result = 3;
        if (dvol > 21) { 
            result = 1;
        } else if (len >= 5) {
            dvol = 21;
            if (dvol < p) {
                result = 1;
            } else if (dvol == p) {
                result = 2;
            };
        } else {
            if (dvol < p) {
                result = 1;
            }else if (dvol == p) {
                result = 2;
            };
        };
        result
    }
}
