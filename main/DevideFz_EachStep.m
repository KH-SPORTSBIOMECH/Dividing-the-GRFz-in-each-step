```python
clc
clear

[S.filename, S.pathname, ~] = uigetfile('C:/Users', 'すべてのファイル', '*.*');
Data = readtable([S.pathname S.filename], 'VariableNamingRule', 'preserve' );  

S.GRF_Sampringrate = 1000;

%%
GRF = Data(5:end, :);
Fx = GRF.Var3 * -1;
Fy = GRF.Var4 * -1;
Fz = GRF.Var5 * -1;

figure;
plot(Fz, "k")
xlabel('Frame', 'FontSize', 14);
ylabel('Force (N)', 'FontSize', 14);
ax = gca;
ax.FontSize = 14;
ax.FontName = 'Times New Roman';
% Check the thlethould values (th1 and th2) and START/END point of the analysis phase 

%%
S.START = 1000;
S.END = 5500;

S.th1 = 50;
S.th2 = 10;

[Rs.Fx,~,~, S.CT_points, S.TOFF_points] = getEachSteps(Fx, Fz, S.START, S.END, S.th1, S.th2, "Fz", 0);
[Rs.Fy,~,~, S.CT_points, S.TOFF_points] = getEachSteps(Fy, Fz, S.START, S.END, S.th1, S.th2, "Fz", 0);
[Rs.Fz,~,~, S.CT_points, S.TOFF_points] = getEachSteps(Fz, Fz, S.START, S.END, S.th1, S.th2, "Fz", 1);

%%
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

function [Rs_table] = CELL2TABLE(CELL, VarName)
    max_length = max(cellfun(@numel, CELL));
    % 各セルの要素の長さを最大の長さに合わせ、不足部分はNaNで埋める
    padded_cell_array = cellfun(@(x) [x(:); nan(max_length - numel(x), 1)], CELL, 'UniformOutput', false);
    % セル配列を行列に変換
    Var = cell2mat(padded_cell_array);
    % 行列を使用してテーブルを作成
    Rs_table = array2table(Var);
    Rs_table.Properties.VariableNames = strcat(VarName, Rs_table.Properties.VariableNames);
end

```

