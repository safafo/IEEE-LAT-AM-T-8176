
 for i=1:34   
    for k=1:25
        if k==1||k==25
        %eval(strcat('lb(i,k)=L',num2str(Carregamento{i,4}),'(1)-l_pv(1);'));
        eval(strcat('lb(i,k)=L',num2str(Carregamento{i,4}),'(1)*Carregamento{i,3}-l_pv(1)*pd_pv(i);'));
        else
        %eval(strcat('lb(i,k)=L',num2str(Carregamento{i,4}),'(k*4)-l_pv(k);'));
        eval(strcat('lb(i,k)=L',num2str(Carregamento{i,4}),'(k*4)*Carregamento{i,3}-l_pv(k)*pd_pv(i);'));
        end  
    end
    p_dbess(i)=min(lb(i,:));
    lb(i,:)=lb(i,:)/(p_dbess(i)*-1);
     
 end

 figure (20)
 
 plot (lb(1,:));
 hold on;
 plot (L1(1:1:3));
 hold on;
 plot(L1(4:4:96));
 hold on;
 plot (l_pv);
 grid on;
 hold off;