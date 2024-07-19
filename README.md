# 周期的な地面反力を波形を分割する

ランニングやジャンプなどで観察される周期的な地面反力波形（図1）を鉛直地面反力（Fz）を基準に各接地ごとに分割して取得します。

![RJ_Fz](https://github.com/user-attachments/assets/e583d77e-7f5b-4921-aa03-a0f0d49d0881)

図1. リバウンドジャンプ時の鉛直地面反力

## Matlab

``` matlab
function [AllSteps, FirstSteps, SecondSteps, CT_points, TOFF_points] = getEachSteps(PARAM, Fz, START, END, th1, th2, PARAM_NAME, FIG)
    % 閾値1
    th_MainData = PARAM(START:END+1);
    th_FzData = Fz(START:END+1);
    Frame = linspace(1, size(th_FzData, 1), size(th_FzData, 1)).';

    if FIG == 2
        plot(th_MainData(1:1000))
    end

    data_th1 = (th_FzData <= th1);
    diff_data_th1 = diff(data_th1);
    switch_points_th1 = find(abs(diff_data_th1) == 1 ) + 1;
        
    % 閾値１で設定した接地瞬間・離地瞬間のポイントを特定
    CT_points = [];
    TOFF_points = [];
    for i = 1:2:length(switch_points_th1)
        CT_points = [CT_points; switch_points_th1(i)];
    end
    
    for i = 2:2:length(switch_points_th1)
        TOFF_points = [TOFF_points; switch_points_th1(i)];
    end

    if FIG == 1
        % Figure: FzとCT, Toffのポイントすべて(th1まで)
        figure()
        hold on;
        plot(th_FzData, 'k')

        line(xlim, [0, 0], 'Color', 'k', 'LineStyle', '-');
        line(xlim, [0, 0], 'Color', 'k', 'LineStyle', '-');

        % CT_points：接地瞬間（赤）
        for i = 1:length(CT_points)
            x = CT_points(i);
            line([x, x], ylim, 'Color', 'r', 'LineStyle', '-');
        end

        % TOFF_points：離地瞬間（青）
        for i = 1:length(TOFF_points)
            x = TOFF_points(i);
            line([x, x], ylim, 'Color', 'b', 'LineStyle', '-');
        end
        
        xlabel('Frame', 'FontSize', 14);
        ylabel('Force (N)', 'FontSize', 14);
        ax = gca;
        ax.FontSize = 14;
        ax.FontName = 'Times New Roman';
        hold off; 
    end

    %%閾値2,　各ステップの局面を取得
    Phase_th2 = [];
    % ALL steps
    for k = 1:length(CT_points)
        ADD_POINT = 10;
        StancePhase_Fz_i = th_FzData(CT_points(k)-ADD_POINT:TOFF_points(k)+ADD_POINT);
        StancePhase_Main_i = th_MainData(CT_points(k)-ADD_POINT:TOFF_points(k)+ADD_POINT);
    
        Phase_th2{k} = StancePhase_Main_i(StancePhase_Fz_i >= th2); %Fzがth2以上の値を取得
    end
    AllSteps = CELL2TABLE(Phase_th2, PARAM_NAME);

    % Right OR Left steps
    Phase_th2_1 = [];
    for k = 1:2:length(CT_points)
        ADD_POINT = 20;
        StancePhase_Fz_i = th_FzData(CT_points(k)-ADD_POINT:TOFF_points(k)+ADD_POINT);
        StancePhase_Main_i = th_MainData(CT_points(k)-ADD_POINT:TOFF_points(k)+ADD_POINT);
        %Frame_i = Frame(CT_points(k)-ADD_POINT:TOFF_points(k)+ADD_POINT);
    
        Phase_th2_1{k} = StancePhase_Main_i(StancePhase_Fz_i >= th2); %Fzがth2以上の値を取得
    end
    FirstSteps = CELL2TABLE(Phase_th2_1, PARAM_NAME);
    
    Phase_th2_2 = [];
    for k = 2:2:length(CT_points)
        ADD_POINT = 20;
        StancePhase_Fz_i = th_FzData(CT_points(k)-ADD_POINT:TOFF_points(k)+ADD_POINT);
        StancePhase_Main_i = th_MainData(CT_points(k)-ADD_POINT:TOFF_points(k)+ADD_POINT);
        %Frame_i = Frame(CT_points(k)-ADD_POINT:TOFF_points(k)+ADD_POINT);
    
        Phase_th2_2{k} = StancePhase_Main_i(StancePhase_Fz_i >= th2); %Fzがth2以上の値を取得
    end
    SecondSteps = CELL2TABLE(Phase_th2_2, PARAM_NAME);

    disp("Steps: "+size(AllSteps,2))

    if FIG == 1
        % Figure: Each steps
        figure;
        hold on;
        for i = 1:size(AllSteps, 2)
            Phase_i_2 = AllSteps{:,i};
            Phase_i_REV = Phase_i_2(~ismissing(Phase_i_2));
            plot(Phase_i_REV);
        end

        xlabel('Frame', 'FontSize', 14);
        ylabel('Force (N)', 'FontSize', 14);
        ax = gca;
        ax.FontSize = 14;
        ax.FontName = 'Times New Roman';
        hold off;
        
    end
end

```

1. 関数`getEachSteps(PARAM, Fz, START, END, th1, th2, PARAM_NAME, FIG)`内の各変数について

    `PARAM`と`Fz`はdouble型であり、それぞれ`取得したい変数`と`基準となるFz`を入力します。

    `START, END`に数値を入力することで解析する局面をトリミングすることが可能です。

    `th1, th2`は、Fzの接地瞬間と離地瞬間の基準となる閾値です。まず、`th1`で大まかな閾値を設定しましょう。これは、Fzの出ることのない滞空局面でth2を超えるノイズが出現した際に有効な手段となります。

    70行目の`ADD_POINT = 10;`でth1の地点から前後10ポイントのFzデータを格納します： `StancePhase_Fz_i = th_FzData(CT_points(k)-ADD_POINT:TOFF_points(k)+ADD_POINT);`。

    格納したデータから`th2`以上のデータを取得することで接地局面のデータを取得することができます： `Phase_th2{k} = StancePhase_Main_i(StancePhase_Fz_i >= th2);`


`PARAM_NAME`,` FIG`














.
