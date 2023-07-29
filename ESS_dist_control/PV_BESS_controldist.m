clear all
close all
clc

%%Inicializa o OpenDSS
%Cria o Obbeto OpenDSS
DSSobb = actxserver('OpenDSSEngine.DSS');

%Testa se o OpenDSS inciou corretamente
if ~DSSobb.Start(0)
    disp ('Unable to start the OpenDSS Engine');
    return
end

%Configura as interfaces do OpenDSS
DSSText = DSSobb.Text;
DSSCircuit = DSSobb.ActiveCircuit;
DSSSolution = DSSCircuit.Solution;
DSSMon = DSSCircuit.Monitors;
DSSLines = DSSCircuit.Lines;


%Chama o diretorio em os arquivos estão sendo executados
Current_Directory = pwd; %pwd = Identify current folder
OpenDSS_Directory = strcat('(',Current_Directory,'\Rede3\Master.dss)');
DSSText.Command = strjoin({'Compile',OpenDSS_Directory});
DSSText.Command = 'calcvoltagebases';
DSSText.Command = 'set mode=daily';
DSSText.Command = 'set stepsize=15m';
DSSText.Command = 'set number = 96';
DSSText.Command = 'Solve';


% DSSCircuit.SetActiveElement(strcat('load.',LoadsNames{i})); %Ativa uma determinada carga
% DSSCircuit.Loads.daily()

load('dimensionamento.mat')

%      for b = 1:34
%         if Carregamento{b,4} == 0
%             A = strcat('Edit Load.',Carregamento{b,1},' Daily=Ls_0');
%             DSSText.Command = A;
%         elseif Carregamento{b,4} == 1
%             A = strcat('Edit Load.',Carregamento{b,1},' Daily=Ls_1');
%             DSSText.Command = A;
%         elseif Carregamento{b,4} == 2
%             A = strcat('Edit Load.',Carregamento{b,1},' Daily=Ls_2');
%             DSSText.Command = A;
%         elseif Carregamento{b,4} == 3
%            A = strcat('Edit Load.',Carregamento{b,1},' Daily=Ls_3');
%             DSSText.Command = A;
%         end
%     end

%% Simulação Com PV e ESS
f=0;%contador para pegar tensão max e min
cons=32; %define qual consumidor vai ter os gráficos plotados
Simuls =[32]; %Casos de penetração ( 3=20%, 6=40%, 10=60%, 20=100%, 27=120%, 34=140%)
for simul = Simuls
    bat_dist=1;       %flag de ativacao das baterias distribuidas (1=ativo)
    
    %Adicionando os PVs
    OpenDSS_Directory = strcat('(',Current_Directory,'\Rede3\Master.dss)');
    DSSText.Command = strjoin({'Compile',OpenDSS_Directory});
    n_pvs =simul;
    for i = 1:n_pvs
        X = PV_ADD(string(Carregamento{i,102}),i,string(Carregamento{i,2}),pd_pv(i)); %Insere os PVs
        DSSText.Command = X;
    end
   %seta monitor e bases para a simulação
    DSSText.Command = 'New monitor.trafo_P element=Transformer.34101150  terminal=2 mode=1 ppolar=no';
    
    for i=1:simul 
        DSSText.Command = strcat('New monitor.C',num2str(i),' element=Load.',Carregamento{i,1},' terminal=1 mode=1 ppolar=no'); %Gera mon nas cargas 
        DSSText.Command = strcat('New monitor.busc_',num2str(i),' element=Line.',Carregamento{i,103},' terminal=2 mode=1 ppolar=no'); %Gera mon nos barramentos

        if simul ~=0
            DSSText.Command = strcat('New monitor.pv_',num2str(i),' element=PVSystem.PV',num2str(i),' terminal=1 mode=1 ppolar=no'); %Gera mon pv3
            
        end
    end 
    %variavel de perda nas linhas e trafo

    eval(strcat('line_loss',num2str(simul),'=zeros(1,2);'));
    eval(strcat('trafo_loss',num2str(simul),'=zeros(1,2);'));
    eval(strcat('total_loss',num2str(simul),'=zeros(1,2);'));

    %solve para coletar as curvas de gerenciamento      
    DSSText.Command = 'Set voltagebases=[11.4, 0.22, 0.127]';
    DSSText.Command = 'CalcVoltageBases';
    DSSText.Command = 'calcv';
    DSSText.Command = 'set mode=daily';
    DSSText.Command = 'set stepsize=15m';
    DSSText.Command = 'set number = 1'; 
    for i = 1:576
        DSSText.Command = 'Solve';
        
        if n_pvs~=0
             %coleta de dados dos medidores
            for k=1:n_pvs
                name = strcat('pv_',num2str(k));
                DSSMon.name = name;
                aux = zeros(length(DSSMon.Channel(1)),3);
                aux(:,1) = DSSMon.Channel(1); %kW Fase A
                aux(:,2) = DSSMon.Channel(3); %kW Fase B
                aux(:,3) = DSSMon.Channel(5);%kW Fase C
                ppvt(k) = aux(i,1) + aux(i,2) + aux(i,3);  
                
                name = strcat('C',num2str(k));
                DSSMon.name = name;
                aux = zeros(length(DSSMon.Channel(1)),3);
                aux(:,1) = DSSMon.Channel(1); %kW Fase A
                aux(:,2) = DSSMon.Channel(3); %kW Fase B
                aux(:,3) = DSSMon.Channel(5);%kW Fase C
                pc(k) = aux(i,1) + aux(i,2) + aux(i,3);
                
                m_curves(k,i)=(pc(k)+ppvt(k))/(p_ess(k));
                m_curves(k,i+1)= m_curves(k,i);
            end
        end 
    end
        
    %inserção dos bess bunto aos PVs para o caso distribuido-controle manual
    if bat_dist==1
        for i = 1:n_pvs
            Y = BESS_ADD_SC(string(Carregamento{i,102}),i,string(Carregamento{i,2}),(p_ess(i)),cap_bess(i));
            DSSText.Command = Y;
        end
    end
    for i=1:simul
        if bat_dist > 0
                    DSSText.Command = strcat('New monitor.bess_',num2str(i),' element=Storage.BESS',num2str(i),' terminal=1 mode=1 ppolar=no'); %Gera mon pv3
                    DSSText.Command = strcat('New Monitor.bess_',num2str(i),'_soc element=Storage.BESS',num2str(i),' terminal=1 mode=3');
        end
    end
    
    %Gera a matriz zeros com numero de barras pelo numero de intervalos de tempo
    eval(strcat('Tesoes_A_',num2str(simul),'=','zeros(length(Bus_A),96);'))
    eval(strcat('Tesoes_B_',num2str(simul),'=','zeros(length(Bus_B),96);'))
    eval(strcat('Tesoes_C_',num2str(simul),'=','zeros(length(Bus_C),96);'))
    
    eval(strcat('V_0_',num2str(simul),'=zeros(41,96);'))
    eval(strcat('V_1_',num2str(simul),'=zeros(41,96);'))
    eval(strcat('V_2_',num2str(simul),'=zeros(41,96);'))
    
    %%Limpa simulação previsa
    DSSText.Command = 'Cleanup';
    DSSText.Command = 'Redirect LoadShape_6d_continuo.dss';

    %%inicia as simulações de 15 em 15 minutos
    
    DSSText.Command = 'Set voltagebases=[11.4, 0.22, 0.127]';
    DSSText.Command = 'CalcVoltageBases';
    DSSText.Command = 'calcv';
    DSSText.Command = 'set mode=daily';
    DSSText.Command = 'set stepsize=15m';
    DSSText.Command = 'set number = 1';
%     DSSText.Command = 'Cleanup';
    for i = 1:576
       
        DSSText.Command = 'Solve';
        A_Aux = DSSCircuit.AllNodeVmagPUByPhase(1); %Pega todas as tensões em pu para fase a no intervalo i(simulação a cada 15 min)
        B_Aux = DSSCircuit.AllNodeVmagPUByPhase(2);  %Pega todas as tensões em pu para fase b
        C_Aux = DSSCircuit.AllNodeVmagPUByPhase(3);  %Pega todas as tensões em pu para fase c
        
        for k=1:41
            DSSCircuit.SetActiveBus(BusNames{k});
            V0_Aux2(k) = DSSCircuit.ActiveBus.SeqVoltages(1); %Pega todas as magnitudes de tensões para fase a no intervalo i(simulação a cada 15 min)
            V1_Aux2(k) = DSSCircuit.ActiveBus.SeqVoltages(2);  %Pega todas as magnitudes de tensões para fase b
            V2_Aux2(k) = DSSCircuit.ActiveBus.SeqVoltages(3);  %Pega todas as magnitudes de tensões para fase c
        end
        %Distribui por barra as tensões para cada fase
        for b = 1:33
            eval(strcat('Tesoes_A_',num2str(simul),'(b,i) = A_Aux(b);'));
        end
        for b = 1:37
            eval(strcat('Tesoes_B_',num2str(simul),'(b,i) = B_Aux(b);'));
        end
        for b = 1:39
            eval(strcat('Tesoes_C_',num2str(simul),'(b,i) = C_Aux(b);'));
        end
        
        %separação das magnitudes e calculo dos desequilibrios
        for x=1:41
            FD_bar(x)=x;
            eval(strcat('V_0_',num2str(simul),'(x,i)=V0_Aux2(x);'));
            eval(strcat('V_1_',num2str(simul),'(x,i)=V1_Aux2(x);'));
            eval(strcat('V_2_',num2str(simul),'(x,i)=V2_Aux2(x);'));
            eval(strcat('FD_',num2str(simul),'(x,i)=100*V_2_',num2str(simul),'(x,i)/V_1_',num2str(simul),'(x,i);'));
        end  
        
        %controle dos ESS     
        if n_pvs~=0 && bat_dist==1 
             %coleta de dados dos medidores
            for k=1:n_pvs
                name = strcat('pv_',num2str(k));
                DSSMon.name = name;
                aux = zeros(length(DSSMon.Channel(1)),3);
                aux(:,1) = DSSMon.Channel(1); %kW Fase A
                aux(:,2) = DSSMon.Channel(3); %kW Fase B
                aux(:,3) = DSSMon.Channel(5);%kW Fase C
                ppvt(k) = aux(i,1) + aux(i,2) + aux(i,3);  
                
                name = strcat('C',num2str(k));
                DSSMon.name = name;
                aux = zeros(length(DSSMon.Channel(1)),3);
                aux(:,1) = DSSMon.Channel(1); %kW Fase A
                aux(:,2) = DSSMon.Channel(3); %kW Fase B
                aux(:,3) = DSSMon.Channel(5);%kW Fase C
                pc(k) = aux(i,1) + aux(i,2) + aux(i,3);  
                
                name = strcat('busc_',num2str(k));
                DSSMon.name = name;
                aux = zeros(length(DSSMon.Channel(1)),3);
                aux(:,1) = DSSMon.Channel(1); %kW Fase A
                aux(:,2) = DSSMon.Channel(3); %kW Fase B
                aux(:,3) = DSSMon.Channel(5);%kW Fase C
                pg(k) =(aux(i,1) + aux(i,2) + aux(i,3));
                
                name = strcat('bess_',num2str(k),'_soc');
                DSSMon.name = name;
                aux = zeros(length(DSSMon.Channel(1)));
                aux= DSSMon.Channel(1); 
                soc(k)= aux(i);    
                
                ll=0;
                ul(k)=Carregamento{k,3}*0.3;
                pl(k)=pc(k)+ppvt(k);              
            
                %carga
                if pl(k)<ll && (100*soc(k)/cap_bess(k))<100
                    A = strcat('Edit Storage.BESS',num2str(k),' State=charging %charge=',num2str(m_curves(k,i+1)*-100)); 
                    DSSText.Command = A;  
                end
                %espera
                if pl(k)>=ll && pl(k)<ul(k)
                    A = strcat('Edit Storage.BESS',num2str(k),' State=discharging %discharge=0');
                    DSSText.Command = A;
                end
                %descarga
                if (pl(k)>=ul(k))&&(100*soc(k)/cap_bess(k))>12.1 
                    A = strcat('Edit Storage.BESS',num2str(k),' State=discharging %discharge=',num2str(m_curves(k,i+1)*100-(ul(k)*100/p_ess(k))));
                    %(100*(pl(k)-ul(k))/p_ess(k))); usa medidas no tempo
                    DSSText.Command = A;
                end
            end
        end 
      
       eval(strcat('line_loss',num2str(simul),'=line_loss',num2str(simul),'+DSSCircuit.LineLosses();'));
       eval(strcat('total_loss',num2str(simul),'=total_loss',num2str(simul),'+DSSCircuit.Losses();'));
       DSSCircuit.SetActiveElement('Transformer.34101150');
       eval(strcat('trafo_loss',num2str(simul),'=trafo_loss',num2str(simul),'+DSSCircuit.ActiveCktElement.Losses();'));
       
    end %fim do solve
 
    if simul ~= 0
           
        name = strcat('pv_',num2str(cons));
        DSSMon.name = name;
        Pot_PV2 = zeros(length(DSSMon.Channel(1)),3);
        Pot_PV2(:,1) = DSSMon.Channel(1); %kW Fase A
        Pot_PV2(:,2) = DSSMon.Channel(3); %kW Fase B
        Pot_PV2(:,3) = DSSMon.Channel(5);%kW Fase C
        P_PV2 = Pot_PV2(:,1) + Pot_PV2(:,2) + Pot_PV2(:,3);
        
        name = strcat('busc_',num2str(cons));
        DSSMon.name = name;
        Pot_Carga2 = zeros(length(DSSMon.Channel(1)),6);
        Pot_Carga2(:,1) = DSSMon.Channel(1); %kW Fase A
        Pot_Carga2(:,2) = DSSMon.Channel(3); %kW Fase B
        Pot_Carga2(:,3) = DSSMon.Channel(5); %kW Fase C
        Pot_Carga2(:,4) = DSSMon.Channel(2);%kva Fase A
        Pot_Carga2(:,5) = DSSMon.Channel(4);%kva Fase B
        Pot_Carga2(:,6) = DSSMon.Channel(6);%kva Fase C
        
        Pbc2t = Pot_Carga2(:,1) + Pot_Carga2(:,2) + Pot_Carga2(:,3);
        Qbc2t = Pot_Carga2(:,4) + Pot_Carga2(:,5) + Pot_Carga2(:,6);
        
        name = strcat('C',num2str(cons));
        DSSMon.name = name;
        Pot_C2=zeros(length(DSSMon.Channel(1)),6);
        Pot_C2(:,1) = DSSMon.Channel(1); %kW Fase A
        Pot_C2(:,2) = DSSMon.Channel(3); %kW Fase B
        Pot_C2(:,3) = DSSMon.Channel(5); %kW Fase C
        
        P_C2(:,1)=Pot_C2(:,1)+Pot_C2(:,2)+Pot_C2(:,3);
        
        if bat_dist > 0
            name = strcat('bess_',num2str(cons));
            DSSMon.name = name;
            Pot_BESS2=zeros(length(DSSMon.Channel(1)),3);
            Pot_BESS2(:,1) = DSSMon.Channel(1); %kW Fase A
            Pot_BESS2(:,2) = DSSMon.Channel(3); %kW Fase B
            Pot_BESS2(:,3) = DSSMon.Channel(5);%kW Fase C
            P_BESS2 = Pot_BESS2(:,1)+Pot_BESS2(:,2)+Pot_BESS2(:,3);
            
            name = strcat('bess_',num2str(cons),'_soc');
            DSSMon.name = name;
            Pot_BESS2_soc = zeros(length(DSSMon.Channel(1)),1);
            P_BESS2_soc(:,1) = DSSMon.Channel(1);
        end
    end
    
    name = 'trafo_P';
    DSSMon.name = name;
    %Gera o a Matriz Potência no Trafo para simulacao atual
    eval(strcat('Pot_Trafo_',num2str(simul),'=','zeros(length(DSSMon.Channel(1)),6);'));
    eval(strcat('Pot_Trafo_',num2str(simul),'(:,1) = DSSMon.Channel(1);')); %kW Fase A
    eval(strcat('Pot_Trafo_',num2str(simul),'(:,2) = DSSMon.Channel(3);')); %kW Fase B
    eval(strcat('Pot_Trafo_',num2str(simul),'(:,3) = DSSMon.Channel(5);')); %kW Fase C
    eval(strcat('Pot_Trafo_',num2str(simul),'(:,4) = DSSMon.Channel(2);')); %kVAr Fase A
    eval(strcat('Pot_Trafo_',num2str(simul),'(:,5) = DSSMon.Channel(4);')); %kVAr Fase B
    eval(strcat('Pot_Trafo_',num2str(simul),'(:,6) = DSSMon.Channel(6);')); %kVAr Fase C
      
    
    %%PLOTAGEM DOS GRAFICOS
    xtickv=[48:48:576];
    x_Tlabel=[12:12:144]
    
    %Desequilibrio de tensão
    eval(strcat('FD_',num2str(simul),'([7,8,9,15,16,19,20,22,29,35,36,37,41],:)=[];'));
    FD_bar([7,8,9,15,16,19,20,22,29,35,36,37,41])=[];
    limit_min = 0;
    limit_max = 0.6; 
    x = 0:0.075:0.6;
    xlab=strrep(cellstr(num2str( x(:) )),'.',',');
   %plot 
    figure('Name',strcat('Simulação ',num2str(simul)))
    pcolor(eval(strcat('FD_',num2str(simul))))
    if simul == 0
        title(strcat('Desequilíbrio de tensão para 0% de Penetração PV-ESS'))
    end
    if simul ~= 0
        title(strcat('Desequilíbrio de tensão para',{' '},num2str(round(nd_pv(simul))),'% de Penetração PV-ESS'))
    end
    colormap(jet)
    xlabel('Tempo (Horas)');
    ylabel('Barramento');
    caxis([limit_min limit_max]);
    cbar = colorbar('Ticks',x,'XTickLabel',xlab);
    cbar.Label.String='Desequilíbrio (%)';
    set(gca,'FontWeight','bold','FontSize',25,'FontName','LM Roman 10','XTick',xtickv,'XTickLabel',x_Tlabel,'YTick',1:1:33,'YTickLabel', FD_bar); %'FontSize',10,'YTick',1:1:33,'FontSize',25,
    yax=get(gca,'YAxis');
    set(yax,'FontSize',10);
    yl=get(gca,'ylabel');
    set(yl,'FontSize',25);
    fig=gcf;
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 10 4];
    fig.PaperSize = [10 4];
       
    %Tensoes
    limit_min = 0.95;
    limit_max = 1.06;
    x = 0.95:0.01:1.06;
    xlab=strrep(cellstr(num2str( x(:) )),'.',',');
   %plot fase A
    figure('Name',strcat('Simulação ',num2str(simul)))
    pcolor(eval(strcat('Tesoes_A_',num2str(simul))))
    if simul == 0
        title(strcat('0% de Penetração PV: Fase A'))
    end
    if simul ~= 0
        title(strcat(num2str(round(nd_pv(simul))),'% de Penetração PV: Fase A'))
    end
    colormap(hot)
    xlabel('Tempo (Horas)');
    ylabel('Barramento');
    caxis([limit_min limit_max])
    cbar = colorbar('Ticks',x,'XTickLabel',xlab);
    cbar.Label.String='Tensão (p.u.)';
    set(gca,'FontWeight','bold','FontSize',25,'FontName','LM Roman 10','XTick',xtickv,'XTickLabel',x_Tlabel,'YTick',1:1:33,'YTickLabel',Bus_A); %'FontSize',10,'YTick',1:1:33,'FontSize',25,
    yax=get(gca,'YAxis');
    set(yax,'FontSize',10);
    yl=get(gca,'ylabel');
    set(yl,'FontSize',25);
    fig=gcf;
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 10 4];
    fig.PaperSize = [10 4];
    
    %plot fase B
    figure('Name',strcat('Simulação ',num2str(simul)))
    pcolor(eval(strcat('Tesoes_B_',num2str(simul))))
    if simul == 0
        title('0% de Penetração PV: Fase B')
    end
    if simul ~= 0
        title(strcat(num2str(round(nd_pv(simul))),'% de Penetração PV-ESS: Fase B'))
    end
    colormap(hot)
    xlabel('Tempo (Horas)');
    ylabel('Barramento');
    x;
    caxis([limit_min limit_max])
    cbar = colorbar('Ticks',x,'XTickLabel',xlab);
    cbar.Label.String='Tensão (p.u.)';
    set(gca,'FontWeight','bold','FontSize',25,'FontName','LM Roman 10','XTick',xtickv,'XTickLabel',x_Tlabel,'YTick',1:1:37,'YTickLabel',Bus_B);
    yax=get(gca,'YAxis');
    set(yax,'FontSize',10);
    yl=get(gca,'ylabel');
    set(yl,'FontSize',25);
    fig=gcf;
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 10 4];
    fig.PaperSize = [10 4];
    %plot fase C
    figure('Name',strcat('Simulação ',num2str(simul)))
    pcolor(eval(strcat('Tesoes_C_',num2str(simul))))
    if simul == 0
        title('0% de Penetração PV: Fase C')
    end
    if simul ~= 0
        title(strcat(num2str(round(nd_pv(simul))),'% de Penetração PV: Fase C'))
    end
    colormap(hot)
    xlabel('Tempo (Horas)');
    ylabel('Barramento');
    x;
    caxis([limit_min limit_max])
    cbar = colorbar('Ticks',x,'XTickLabel',xlab);
    cbar.Label.String='Tensão (p.u.)';
    set(gca,'FontWeight','bold','FontSize',25,'FontName','LM Roman 10','XTick',xtickv,'XTickLabel',x_Tlabel,'YTick',1:1:39,'YTickLabel',Bus_C);
    yax=get(gca,'YAxis');
    set(yax,'FontSize',10);
    yl=get(gca,'ylabel');
    set(yl,'FontSize',25);
    fig=gcf;
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 10 4];
    fig.PaperSize = [10 4];
    
    %Potencia no trafo
    figure('Name',strcat('Simulação ',num2str(simul)))
    plot(eval(strcat('-1*Pot_Trafo_',num2str(simul),'(:,1:3)')))
    if simul == 0
        title('Potência de Demanda no Transformador com 0% de Penetração')
    end
     if simul ~= 0
        title(strcat('Potência de Demanda no Transformador com',{' '},num2str(round(nd_pv(simul))),'% de Penetração'))
    end
    grid on,
    xlabel('Tempo (Horas)');
    ylabel('Potência (kW)');
    legend('Pa','Pb','Pc');%'Qa','Qb','Qc')
    set(gca,'FontWeight','bold','LineWidth',1,'FontSize',25,'FontName','LM Roman 10','XTick',xtickv,'XTickLabel',x_Tlabel);
    if simul==0
        ylim([0 11]);
    else
        ylim([-inf 11]);
    end
    fig=gcf;
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 10 4];
    fig.PaperSize = [10 4];
    
    %captura tensões max e min
    f=f+1;
    V_max(f,1)= eval(strcat('max(Tesoes_A_',num2str(simul),'(:))'));
    V_min(f,1)=eval(strcat('min(Tesoes_A_',num2str(simul),'(:))'));
    V_max(f,2)= eval(strcat('max(Tesoes_B_',num2str(simul),'(:))'));
    V_min(f,2)=eval(strcat('min(Tesoes_B_',num2str(simul),'(:))'));
    V_max(f,3)= eval(strcat('max(Tesoes_C_',num2str(simul),'(:))'));
    V_min(f,3)=eval(strcat('min(Tesoes_C_',num2str(simul),'(:))'));
    FD_max(f)=eval(strcat('max(FD_',num2str(simul),'(:))'));
end


figure('Name',strcat('Simulação Potências consumidor ',num2str(cons)))
plot(Pbc2t*(-1));
hold on;
% plot(Qbc2t*-1);
% hold on;
plot(P_PV2);
hold on;
plot(P_C2);
hold on;
if bat_dist~=0
    plot(P_BESS2*-1);
    hold on;
end
grid on;
title(strcat('Potência no PCC - Carga ',num2str(cons)))
xlabel('Tempo(Horas)');
ylabel('Potência (kVA)');
%,'Qmedida',
legend('Pmedida','Geração PV','P Consumo','P ESS');
set(gca,'FontWeight','bold','LineWidth',1,'FontSize',25,'FontName','LM Roman 10','XTick',xtickv,'XTickLabel',x_Tlabel);
fig=gcf;
fig.PaperUnits = 'inches';
fig.PaperPosition = [0 0 10 4];
fig.PaperSize = [10 4];
hold off;

if bat_dist>0
    figure('Name',strcat('Simulação ESS ',num2str(cons)))
    plot(P_BESS2_soc);
    grid on;
    title(strcat('Estado de carga do ESS ',num2str(cons)))
    xlabel('Tempo(Horas)');
    ylabel('Carga (kWh)');
    legend('Pmedida','Qmedida','Geração PV','P Consumo','P ESS');
    set(gca,'FontWeight','bold','LineWidth',1,'FontSize',25,'FontName','LM Roman 10','XTick',xtickv,'XTickLabel',x_Tlabel);
    fig=gcf;
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 10 4];
    fig.PaperSize = [10 4];
end


% figure('Name','Curva de despacho')
% plot(L3(:)*Carregamento{2,3})
% hold on 
% plot (l_pv(:,4)*pd_pv(2),'-o')
% hold on 
% plot(lb(2,:)*p_ess(2),'-+')
% grid on;
% title('Perfis de carga absolutos no Prosumidor 2')
% xlabel('Time (Hours)');
% ylabel('Power (kW)');
% % legend('Consumption','PV Generation','ESS');
% legend('Installed Load','PV Generation','Consumption');
% set(gca,'FontWeight','bold','LineWidth',1,'FontSize',25,'FontName','LM Roman 10','XTick',xtickv,'XTickLabel',x_Tlabel);
% fig=gcf;
% fig.PaperUnits = 'inches';
% fig.PaperPosition = [0 0 10 4];
% fig.PaperSize = [10 4];



%      for b = 1:34
%         if Carregamento{b,4} == 0
%             A = strcat('Edit Load.',Carregamento{b,1},' Daily=continuo_0');
%             DSSText.Command = A;
%         elseif Carregamento{b,4} == 1
%             A = strcat('Edit Load.',Carregamento{b,1},' Daily=continuo_1');
%             DSSText.Command = A;
%         elseif Carregamento{b,4} == 2
%             A = strcat('Edit Load.',Carregamento{b,1},' Daily=continuo_2');
%             DSSText.Command = A;
%         elseif Carregamento{b,4} == 3
%            A = strcat('Edit Load.',Carregamento{b,1},' Daily=continuo_3');
%             DSSText.Command = A;
%         end
%     end
   
% figure('Name',strcat('Simulação Potências consumidor ',num2str(cons)))
% plot(p_ess);
% hold on;
% % plot(Qbc2t*-1);
% % hold on;
% plot(p_ess);
% hold on;
% plot(p_ess);
% hold on;
% 
%    plot(p_ess);
%     hold on;
% grid on;
% title(strcat('Potência no PCC - Carga ',num2str(cons)))
% xlabel('Time(Hours)');
% ylabel('Power (kVA)');
% %,'Qmedida',
% legend('Grid','PV','Load','ESS');
% set(gca,'FontWeight','bold','LineWidth',1,'FontSize',25,'FontName','LM Roman 10');
% fig=gcf;
% fig.PaperUnits = 'inches';
% fig.PaperPosition = [0 0 10 4];
% fig.PaperSize = [10 4];
% hold off;

