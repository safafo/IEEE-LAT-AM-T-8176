close all
figure('Name',strcat('Simulação ',num2str(simul)))
lim_trafo=(45)+zeros(1,96);
for z= Simuls 
        P=eval(strcat('transpose(-1*sum(Pot_Trafo_',num2str(z),'(:,1:3),2));'));
        Q=eval(strcat('transpose(-1*sum(Pot_Trafo_',num2str(z),'(:,4:6),2));'));
       for x=1:96
           if P(x)>0
               fp(x)=cosd(atand(Q(x)/P(x)));
           else
               fp(x)=cosd(90+atand(Q(x)/P(x)));
           end
           S(x)=P(x)/fp(x);
       end 
       
        if z~=0
             plot(S,'DisplayName',strcat('S',num2str(round(nd_pv(z))),'%')); 
    else
         plot(S,'DisplayName','S 0%');
    hold on;
        end    
end
% plot(lim_trafo,'color','r','DisplayName','Limite');
hold off;
    title(strcat('Potência Aparente no transformador para diferentes níveis de penetração PV-ESS')) 
    grid on,
    xlabel('Tempo (Horas)');
    ylabel('Potência (kVA)');
    legend show
    set(gca,'FontWeight','bold','LineWidth',1,'FontSize',25,'FontName','LM Roman 10','XTick',xtickv,'XTickLabel',2:2:24);
    fig=gcf;
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 10 4];
    fig.PaperSize = [10 4];

    figure('Name',strcat('Simulação_fp ',num2str(simul)))
    for z= Simuls 
        P=eval(strcat('transpose(sum(Pot_Trafo_',num2str(z),'(:,1:3),2));'));
        Q=eval(strcat('transpose(sum(Pot_Trafo_',num2str(z),'(:,4:6),2));'));
       for x=1:96
           if P(x)<0
               fp(x)=cosd(atand(Q(x)/P(x)));
           else
               fp(x)=cosd(180+atand(Q(x)/P(x)));
           end
       end 
       
        if z~=0
             plot(fp,'DisplayName',strcat('FP ',num2str(round(nd_pv(z))),'%')); 
    else
         plot(fp,'DisplayName','FP 0%');
    hold on;
    end
end
hold off;
    title(strcat('Fator de Potência no transformador para diferentes níveis de penetração PV-ESS')) 
    grid on,
    xlabel('Tempo (Horas)');
    ylabel('Fator de Potência');
    legend show
    set(gca,'FontWeight','bold','LineWidth',1,'FontSize',25,'FontName','LM Roman 10','YTick',-1:0.25:1,'XTick',xtickv,'XTickLabel',2:2:24);
    fig=gcf;
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 10 4];
    fig.PaperSize = [10 4];