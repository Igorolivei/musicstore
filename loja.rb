require 'sinatra'
require 'sinatra/activerecord'
require './produto.rb'
require './usuario.rb'
require './tipo.rb'
require './genero.rb'
require './artista.rb'
require './venda.rb'
require './produtosvendido.rb'
require './statu.rb'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => './loja.db')

enable :sessions

get '/' do
	erb :inicio
end

get '/sobre' do
	erb :sobre
end

get '/produtos_lista' do
	@tipos = Tipo.all
  @generos = Genero.all
  @artistas = Artista.all
  @produtos = Produto.all
  erb :produtos_lista
end

get '/carrinho' do
  @tipos = Tipo.all
  @generos = Genero.all
  @artistas = Artista.all
  @carrinho_lista = Produto.where("id IN (?)", session[:id_carrinho])
	erb :carrinho
end

post '/carrinho_add' do
  if session[:id_carrinho] == nil
    session[:id_carrinho] = []
  end

  session[:id_carrinho] << params[:id_carrinho]

  redirect '/produtos_lista'
end

get '/produtos_cadastro' do
  @tipos = Tipo.all
  @generos = Genero.all
  @artistas = Artista.all

  erb :produtos_cadastro
end

post '/produtos_cadastro' do
  @novo_produto = Produto.new(:nome => params[:nome], :preco => params[:preco], :ano => params[:ano], :id_artista => params[:artista], :id_tipo => params[:tipo], :id_genero => params[:genero])
  @novo_produto.save
  
  #if session[:produtos_cadastrados] == nil
	# session[:produtos_cadastrados] = []
  #end 
  
  #session[:produtos_cadastrados] << novo_produto
  
  redirect '/produtos_lista'
end

post '/limpar_carrinho' do
  session[:id_carrinho] = nil
  redirect '/carrinho'
end

get '/produtos_editar' do
  @tipos = Tipo.all
  @generos = Genero.all
  @artistas = Artista.all
  @produtos_editar = Produto.where("id IN (?)", params[:id_editar])
  erb :produtos_editar
end

post '/produtos_editar' do
  @produto = Produto.find(params[:id_editar])
  @produto.nome = params[:nome_editar]
  @produto.preco = params[:preco_editar]
  @produto.save

  redirect '/produtos_lista'
end

post '/produtos_remover' do
  @produto = Produto.find(params[:id_remover]).destroy

  redirect '/produtos_lista'
end

get '/clientes_cadastro' do
  #Formulário de cliente
  erb :cliente_cadastro
end

post '/cliente_cadastro' do
  #Cadastro de clientes no banco de dados
  if params[:senha] != nil && params[:senha] == params[:confirma_senha]
    @cliente = Usuario.new(:nome => params[:nome], :email => params[:email], :senha => params[:senha], :tipo_usuario => 1)
    @cliente.save
    if session[:admin_logado] == nil || session[:admin_logado] == [] && session[:cliente_logado] == nil || session[:cliente_logado] == []
      session[:admin_logado] = []
      session[:cliente_logado] = @cliente.id
    else
      redirect '/clientes_cadastro'
    end
  else
    redirect '/clientes_cadastro'
  end
  redirect '/'
end

get '/admin_cadastro' do
  #Formulário de administrador
  erb :admin_cadastro
end

post '/admin_cadastro' do
  #Cadastro de administradores no banco de dados
  if params[:senha] != nil && params[:senha] == params[:confirma_senha]
    @admin = Usuario.new(:nome => params[:nome], :email => params[:email], :senha => params[:senha], :tipo_usuario => 0)
    @admin.save
  else
    redirect '/admin_cadastro'
  end
  redirect '/'
end

post '/autenticar' do
  #TESTAR LOGIN/SENHA
  # PESQUISA SE EXISTE UM CLIENTE COM ESSE EMAIL E ESSA SENHA
  encontrado = Usuario.where("email = ? AND senha = ?", params[:email], params[:senha])
  
  if session[:admin_logado] == nil
    session[:admin_logado] = []
  end

  if session[:cliente_logado] == nil
    session[:cliente_logado] == []
  end

  if encontrado.size == 0
    # NÃO ACHOU
    redirect '/'
  else
    # ACHOU!!!!!
    #Se é administrador
    if encontrado[0].tipo_usuario == 0
      session[:admin_logado] = encontrado[0].id
    #Se é cliente
    else
      session[:cliente_logado] = encontrado[0].id
    end
    redirect '/'
  end
end

get '/logout' do
  #session.destroy para remover tudo (inclusive carrinho)
  session[:admin_logado] = nil
  session[:cliente_logado] = nil
  session[:id_carrinho] = nil
  session[:valor_total] = nil
  redirect '/'
end

post '/venda' do
  #Cadastra nova venda pra pegar o id e usar no produto vendido
  if session[:admin_logado] != nil || session[:admin_logado] != []
    @venda = Venda.new(:id_usuario => session[:admin_logado], :id_status => 1, :valor_total => session[:valor_total]) 
  elsif session[:cliente_logado] != nil || session[:cliente_logado] != []
    @venda = Venda.new(:id_usuario => session[:cliente_logado], :id_status => 1, :valor_total => session[:valor_total]) 
  else
    redirect '/carrinho_lista'
  end
  @venda.save
  #Pega os produtos do carrinho
  @carrinho_lista = Produto.where("id IN (?)", session[:id_carrinho])
  #Percorre os produtos do carrinho
  @carrinho_lista.each do |p|
    quantidade = session[:id_carrinho].select{|e| e.to_i==p.id}.size
    valor_total = p.preco * quantidade
    if session[:admin_logado] != nil || session[:admin_logado] != []
    @produto_vendido = Produtosvendido.new(:id_venda => @venda.id, :id_usuario => session[:admin_logado], :id_produto => p.id, :valor_parcial => valor_total, :quantidade => quantidade)
    elsif session[:cliente_logado] != nil || session[:cliente_logado] != []
      @produto_vendido = Produtosvendido.new(:id_venda => @venda.id, :id_usuario => session[:cliente_logado], :id_produto => p.id, :valor_parcial => valor_total, :quantidade => quantidade)
    else
      redirect '/carrinho_lista'
    end
    @produto_vendido.save
  end
  #venda.save
  #venda.where(tudo igual).last
  #venda.id
  #Limpa o carrinho depois da compra
  session[:id_carrinho] = nil
  redirect '/produtos_lista'
end

get "/clientes_visualizar" do
  @clientes = Usuario.where("tipo_usuario = 1")
  erb :cliente_visualizar
end

post "/clientes_remover" do
  @clientes = Usuario.find(params[:id_remover]).destroy
  redirect '/clientes_visualizar'
end

get "/vendas_lista" do
  @status = Statu.all
  @vendas = Venda.all
  erb :vendas
end

post "/editar_venda" do
  @venda = Venda.find(params[:venda_editar])
  @venda.id_status = params[:status]
  @venda.save
  redirect '/vendas_lista'
end