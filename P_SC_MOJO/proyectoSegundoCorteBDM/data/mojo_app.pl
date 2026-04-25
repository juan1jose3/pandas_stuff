use Mojolicious::Lite;
use DBI;
use MongoDB;
use JSON;
use File::Slurp;
use Data::Dumper;
use Mojo::JSON qw(decode_json);
use Mojo::UserAgent;



# Conectar a la base de datos sqlite

my $dsn = "dbi:SQLite:dbname=/app/almacen.sqlite";


my $dbh = DBI->connect($dsn, "", "", { 
    RaiseError     => 1, 
    AutoCommit     => 1,
    sqlite_unicode => 1
}) or die $DBI::errstr;

# Conectar a MongoDB para cada colección en sus respectivos contenedores

my $mongo_personas  = MongoDB->connect('mongodb://root:root@mongodb_personas:27017');
my $mongo_articulos = MongoDB->connect('mongodb://root:root@mongodb_articulos:27017');
my $mongo_ventas    = MongoDB->connect('mongodb://root:root@mongodb_ventas:27017');

sub get_result_personas {  
    my @list;
    eval {
       
        my $client = MongoDB->connect('mongodb://root:root@mongodb_personas:27017/?connectTimeoutMS=5000');
        
        my $db = $client->get_database('base_personas');
        my $collection = $db->get_collection('personas');

      
        my $cursor = $collection->find->limit(10);
        
        while (my $doc = $cursor->next) {
            $doc->{_id} = "$doc->{_id}";
            push @list, $doc;
        }
    };

    if ($@) {
        return [{ error => "Perl Exception: $@" }];
    }

    if (!@list) {
        return [{ status => "Connected, but collection 'personas' is empty" }];
    }

    return \@list;
}


sub get_result_articulos {  
    my @list;
    eval {
        
        my $client = MongoDB->connect('mongodb://root:root@mongodb_articulos:27017/?connectTimeoutMS=5000');
        my $db     = $client->get_database('base_articulos');
        my $col    = $db->get_collection('articulos');

        
        my $cursor = $col->find->limit(10); 
        
        while (my $doc = $cursor->next) {
            $doc->{_id} = "$doc->{_id}"; # Stringify for JSON
            push @list, $doc;
        }
    };
    if ($@) { return [{ error => "Perl Articulos Exception: $@" }]; }
    if (!@list) { return [{ status => "Articulos empty" }]; }

    return \@list;
}

sub get_result_ventas {  
    my @list;
    eval {
        my $client = MongoDB->connect('mongodb://root:root@mongodb_ventas:27017/?connectTimeoutMS=5000');
        my $db     = $client->get_database('base_ventas');
        my $col    = $db->get_collection('ventas');

        my $cursor = $col->find->limit(10); 
        
        while (my $doc = $cursor->next) {
            $doc->{_id} = "$doc->{_id}";
            push @list, $doc;
        }
    };
    if ($@) { return [{ error => "Perl Ventas Exception: $@" }]; }
    if (!@list) { return [{ status => "Ventas empty" }]; }

    return \@list;
}


# Función para cargar datos desde archivos JSON a MongoDB
sub load_data_to_mongo {

    my $c = shift; 

   
    etl_process_personas();
    etl_process_articulos();
    etl_process_ventas();

    
    $c->render(json => { message => "All systems loaded" });
}

# Función para registrar mensajes de depuración
sub log_debug {
    my ($message) = @_;
    my $log_file = '/app/data/debug.log'; 
    open(my $fh, '>>', $log_file) or return;  
    print $fh localtime() . " - $message\n";  
    close $fh;
}


# Función para extraer y cargar personas
sub etl_process_personas {
    
    my $json_text = read_file('/app/personas.json');
    my $data = decode_json($json_text);
    my $col = $mongo_personas->get_database('base_personas')->get_collection('personas');
    $col->insert_many($data);
    
    log_debug("Personas loaded successfully");
}



# Función para extraer y cargar artículos
sub etl_process_articulos {
    
    my $json_text = read_file('/app/articulos.json');
    my $data = decode_json($json_text);
    my $col = $mongo_articulos->get_database('base_articulos')->get_collection('articulos');
    $col->insert_many($data);
    
    log_debug("Articulos loaded successfully");
 
}

# Función para extraer y cargar ventas
sub etl_process_ventas {
    
    my $json_text = read_file('/app/ventas.json');
    my $data = decode_json($json_text);
    my $col = $mongo_ventas->get_database('base_ventas')->get_collection('ventas');
    $col->insert_many($data);
    
    log_debug("Ventas loaded successfully");
 
}


sub limpiar_numerico {
    my ($val) = @_;
    return 0 unless defined $val;
    (my $clean = "$val") =~ s/[^0-9.]//g;
    return length($clean) ? $clean + 0 : 0;
}


# Rutas para cargar datos
get '/load_data' => sub {
    my $c = shift;
    load_data_to_mongo($c);
};

# Rutas para obtener datos de MongoDB
get '/mongo/personas' => sub {
    my $c = shift;

    my $data = get_result_personas();

    $c->render(json => $data);


};

get '/mongo/articulos' => sub {
    my $c = shift;
    my $data = get_result_articulos();
    $c->render(json => $data);
};

get '/mongo/ventas' => sub {
    my $c = shift;
    my $data = get_result_ventas();
    $c->render(json => $data);
};


get '/mongo/personas/all' => sub {
    my $c = shift;
    my @list;
    eval {
        my $col = MongoDB->connect('mongodb://root:root@mongodb_personas:27017/?connectTimeoutMS=10000')
            ->get_database('base_personas')->get_collection('personas');
        my $cursor = $col->find;
        while (my $doc = $cursor->next) {
            $doc->{_id} = "$doc->{_id}";
            push @list, $doc;
        }
    };
    $c->render(json => ($@ ? [{ error => "$@" }] : \@list));
};

get '/mongo/articulos/all' => sub {
    my $c = shift;
    my @list;
    eval {
        my $col = MongoDB->connect('mongodb://root:root@mongodb_articulos:27017/?connectTimeoutMS=10000')
            ->get_database('base_articulos')->get_collection('articulos');
        my $cursor = $col->find;
        while (my $doc = $cursor->next) {
            $doc->{_id} = "$doc->{_id}";
            push @list, $doc;
        }
    };
    $c->render(json => ($@ ? [{ error => "$@" }] : \@list));
};

get '/mongo/ventas/all' => sub {
    my $c = shift;
    my @list;
    eval {
        my $col = MongoDB->connect('mongodb://root:root@mongodb_ventas:27017/?connectTimeoutMS=10000')
            ->get_database('base_ventas')->get_collection('ventas');
        my $cursor = $col->find;
        while (my $doc = $cursor->next) {
            $doc->{_id} = "$doc->{_id}";
            push @list, $doc;
        }
    };
    $c->render(json => ($@ ? [{ error => "$@" }] : \@list));
};

# Rutas para obtener datos de SQLite
get '/sqlite/personas' => sub {

};

get '/sqlite/articulos' => sub {

};

get '/sqlite/ventas' => sub {

};

# Agregar una nueva persona
post '/sqlite/personas' => sub {
    
};

# Agregar un nuevo artículo
post '/sqlite/articulos' => sub {
 
};

# Agregar una nueva venta
post '/sqlite/ventas' => sub {

};


# Iniciar la aplicación Mojolicious
app->start;
