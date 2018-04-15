# Create-Sequence.ps1
# requires -version 1
#
# Create a sequence object similar to an Oracle sequence.
#
# see : http://www.acs.ilstu.edu/docs/oracle/server.101/b10759/statements_6014.htm
#
# Crée un objet séquence similaire à une séquence Oracle
# Version spécifique à PowerShell v1.0

# L'appel de Nextval n'est pas nécessaire CurrVal est accessible dés que l'objet créé
   

#Propriétés en ReadOnly: 
#-----------------------------------------------------------------------------------------

#Tutorial (french) : http://laurent-dardenne.developpez.com/articles/Windows/PowerShell/CreationDeMembresSynthetiquesSousPowerShell/

# Name         : Nom de la séquence.
#
# CurrVal      : Contient la valeur courante. 
#
# Increment_By : Spécifie l'interval entre les numéros de la séquence. 
#                Cette valeur entiére peut être n'importe quel nombre entier positif ou négatif de type .NET INT, mais elle ne peut pas être 0. 
#                L'absolu de cette valeur doit être moins (ou égal) que la différence de MAXVALUE et de MINVALUE. 
#                Si cette valeur est négative, alors le séquence est descendante (ordre décroissant). 
#                Si la valeur est positive, alors la séquence est ascendante (ordres croissant). 
#                Si vous omettez ce paramètre la valeur de l'interval est par défaut de 1.
#
# Start_With   : Spécifie le premier nombre de la séquence à produire. 
#                Employez ce paramètre pour démarrer une séquence ascendante à une valeur plus grande que son minimum ou pour  
#                démarrer une séquence descendante à une valeur moindre que son maximum. Pour des séquences ascendantes, 
#                la valeur par défaut est la valeur minimum de la séquence. Pour des séquences descendantes, la valeur par défaut 
#                est la valeur maximum de la séquence.
#                Note :
#                 Cette valeur n'est pas nécessairement la valeur à laquelle une séquence ascendante cyclique redémarre une fois 
#                 sa valeur maximum ou minimum atteinte. 
#
# MaxValue     : Spécifie la valeur maximum que la séquence peut produire. 
#                MAXVALUE doit être égal ou plus grand que le valeur du paramètre START_WITH et doit être plus grand que MINVALUE.
#
# MinValue     : Spécifie la valeur minimum de la séquence. 
#                MINVALUE doit être inférieur ou égal à le valeur du paramètre START_WITH  et doit être inférieure à MAXVALUE.
#
# Cycle        : Indique que la séquence continue à produire des valeurs une fois atteinte sa valeur maximum ou minimum. 
#                Une fois qu'une séquence ascendante a atteint sa valeur maximum, elle reprend à sa valeur minimum. 
#                Une fois qu'une séquence descendante a atteint sa valeur minimum, elle reprend à sa valeur maximum.
#                Par défaut une séquence ne produit plus de valeurs une fois atteinte sa valeur maximum ou minimum. 
#
# Comment      : Commentaire.
#
#Méthodes :
#-----------------------------------------------------------------------------------------
# NextVal: Incrémente la séquence et retourne la nouvelle valeur.



# ** Le fonctionnment de cet objet séquence est similaire à celui d'une séquence Oracle sans pour autant être identique.

# Si vous ne spécifiez aucun paramètre, autre que le nom obligatoire, alors vous créez une séquence ascendante qui 
# débute à 1 et est incrémentée de 1 jusqu'à sa limite supérieure ([int]::MaxValue). 
# Si vous spécifiez seulement INCREMENT_BY -1 vous créez une séquence déscendante qui débute à -1 et 
# est décrémentée de 1 jusqu'à sa limite inférieure ([int]::MinValue).

# Pour créer une séquence ascendante qui incrémente sans limite (autre que celle du type .NET INT), omettez le paramètre MAXVALUE. 
# Pour créer une séquence descendante qui décrémente sans limite, omettez le paramètre MINVALUE.

# Pour créer une séquence ascendante qui s'arrête à une limite prédéfinie, spécifiez une valeur pour le paramètre MAXVALUE. 
# Pour créer une séquence descendante qui s'arrête à une limite prédéfinie, spécifiez une valeur pour le paramètre MINVALUE. 
# Si vous ne précisez pas le paramètre -CYCLE, n'importe quelle tentative de produire un numéro de séquence une fois que la séquence 
# a atteint sa limite déclenchera une erreur.

# Pour créer une séquence qui redémarre/boucle après avoir atteint une limite prédéfinie, indiquez le paramètre CYCLE. Dans ce cas 
# vous devez obligatoirement spécifiez une valeur pour les paramètres MAXVALUE ou MINVALUE. 

#Valeur par défaut d'une séquence ascendante :
# $Sq=Create-Sequence "SEQ_Test"  ;$Sq
#
# Name         : SEQ_Test
# CurrVal      : 1
# Increment_By : 1
# MaxValue     : 2147483647
# MinValue     : 1
# Start_With   : 1
# Cycle        : False
# Comment      :

#Valeur par défaut d'une séquence descendante :
# $Sq=Create-Sequence "SEQ_Test" -inc -1  ;$Sq
# 
# Name         : SEQ_Test
# CurrVal      : -1
# Increment_By : -1
# MaxValue     : -1
# MinValue     : -2147483648
# Start_With   : -1
# Cycle        : False
# Comment      :

#Exemple :
# $DebugPreference = "Continue"
# $Sq= Create-Sequence "SEQ_Test"
# $Sq.Currval
# $Sq.NextVal()
# $Sq.Currval

Function Create-Sequence
{
  #Tous les paramètres sont contraint, i.e. on précise un type. 
 param([String] $Sequence_Name, 
       [String] $Comment,
       $Increment_By=1,
       $MaxValue,
       $MinValue,
       $Start_With,            
       [switch] $Cycle)

  function ValidateParameter([string]$Name,$Parameter,[Type] $Type)
  {  # Renvoi True si le type est celui attendu et si le contenu n'est pas $Null ou si on peut caster 
     # la valeur reçue dans le type attendu
     # Renvoi False si le contenu est à $Null.
     # Déclenche une exception ArgumentTransformationMetadataException si le type n'est pas celui attendu. 
   
    Write-Debug "ValidateParameter"
    Write-debug "$Name"
    if ($Parameter -ne $null) 
     {Write-debug "$($Parameter.GetType())"}
    else {Write-debug "`$Parameter est à `$null."}
    Write-debug "$Parameter"
    Write-debug "$Type"
    
    
    if (($Parameter -eq $null)) 
    { Write-Debug "Le paramètre $Name est à `$null."
      return $False
    }
    elseif ($Parameter -isNot $Type) 
     {  #Peut-on caster la valeur reçue dans le type attendu ?
       if (!($Parameter -as $Type)) 
        {
         #récupére le contexte d'appel de l'appelant
         $Invocation = (Get-Variable MyInvocation -Scope 1).Value
         throw (new-object System.Management.Automation.ArgumentTransformationMetadataException "$($Invocation.MyCommand).$($MyInvocation.MyCommand) : Impossible de convertir la valeur « $Parameter » en type « $($Type.ToString()) ».")
        }
     } 
    return $True
  } #ValidateParameter 
  write-Debug "[Valeurs des paramètres]"
  write-Debug "Sequence_Name $Sequence_Name"
  write-Debug "Comment $Comment"
  write-Debug "Increment_By $Increment_By" 
  write-Debug "MaxValue $MaxValue"
  write-Debug "MinValue $MinValue"
  write-Debug "Start_With $Start_With"  
  write-Debug "Cycle $Cycle"        


 if (($Sequence_Name -eq $null) -or ($Sequence_Name -eq [String]::Empty))
  {Throw "Nom de séquence invalide. La valeur de Sequence_Name doit être renseignée."}

 write-Debug "Test isTypeEqual terminé."

 if ( (!(ValidateParameter "Increment_By" $Increment_By System.Int32) ) -and ($Increment_By -eq 0) ) 
  {Throw "La valeur de Increment_By doit être un entier différent de zéro."}
     
# Valeur par défaut
# Si on ne spécifie aucun paramètre alors on crée une séquence ascendante qui débute à 1
# est incrémentée de 1 sans limite de valeur supérieure (autre que celle du type utilisé)   
#Si on spécifie seulement -Increment_By -1 on crée une séquence descendante qui débute à -1
# est décrémentée de -1 sans limite de valeur inférieure (autre que celle du type utilisé)
 write-Debug ""
 write-Debug "Les valeurs par défaut pour la séquence de type sont :"

#Ici si $Increment_By n'est pas renseigné il vaut par défaut 1, on ne peut donc avoir 0 comme valeur renvoyée par la méthode Sign 
$local:Signe=[System.Math]::Sign($Increment_By)      
 write-Debug "`tIncrement_By $Increment_By"
 write-Debug "`tSigne $Signe (1= positif  -1= négatif)"
 
 if ( ($Signe -eq 1) -and
       #test si les paramètres  sont à $null
      (!(ValidateParameter "Start_With" $Start_With System.Int32)) -and
      (!(ValidateParameter "MaxValue" $MaxValue System.Int32)) -and
      (!(ValidateParameter "MinValue" $MinValue System.Int32)) 
     )
      { write-Debug "`tSéquence ascendante. Valeur par défaut."
        $Start_With=1     
        $MaxValue=[int]::MaxValue
        $MinValue=1
      }
 elseif 
    ( ($Signe -eq -1) -and
      (!(ValidateParameter "Start_With" $Start_With System.Int32)) -and
      (!(ValidateParameter "MaxValue" $MaxValue System.Int32)) -and
      (!(ValidateParameter "MinValue" $MinValue System.Int32))
     )
      { write-Debug "`tSéquence descendante. Valeur par défaut."
        $Start_With=-1     
        $MaxValue=-1
        $MinValue=[int]::MinValue
      }
 else
  { 
    write-Debug "`t* Pas de valeur par défaut. *"
 
    # Si MaxValue n'est pas spécifié on indique la valeur maximum pour une séquence ascendante 
    # sinon 1 pour une séquence descendante    
    if (!(ValidateParameter "MaxValue" $MaxValue System.Int32))
    { $MaxValue=[int]::MaxValue 
      if ($local:Signe -eq -1)
       {$MaxValue=-1 }
    }
    # Si MinValue n'est pas spécifié on indique la valeur 1 pour une séquence ascendante 
    # sinon la valeur minimum  pour une séquence descendante    
   if (!(ValidateParameter "MinValue" $MinValue System.Int32))
    { $MinValue=1
      if ($Signe -eq -1)
       {$MinValue=[int]::MinValue }
    }
     
     # Si Start_With n'est pas spécifié on indique, pour une séquence ascendante, la valeur minimum de la séquence 
     # ou pour une séquence descendante la valeur maximum de la séquence.
   if (!(ValidateParameter "Start_With" $Start_With System.Int32)) 
    {
     switch ($local:Signe)
      { 
        1  {$Start_With=$MinValue}
       -1  {$Start_With=$MaxValue}
      }#switch    
    }#If
 }#else 
 
 write-Debug "Start_With $Start_With"
 write-Debug "MaxValue $MaxValue"
 write-Debug "MinValue $MinValue"

 if (!(ValidateParameter "Increment_By" $Increment_By System.Int32))
  { 
   if ($Cycle.Ispresent) 
    { #Dans ce cas selon le signe du paramètre $Increment_By on doit préciser soit Minvalue soit MaxValue  
     switch ($local:Signe)
      { 
       1  { if (!(ValidateParameter "MinValue" $MinValue System.Int32)) 
             { Throw "Séquence ascendante cyclique pour laquelle vous devez spécifier MinValue."}
          }
      -1  { if (!(ValidateParameter "MaxValue" $MaxValue System.Int32))
            { Throw "Séquence descendante cyclique pour laquelle vous devez spécifier MaxValue."}
          }
      default  { Throw "Analyse erronée!"}
      }#switch
    }#if cycle
  }#if increment
 write-Debug "Test de la variable Cycle terminé."      
 write-Debug "[Test de validité de la séquence]"     

 # MINVALUE must be less than or equal to START WITH and must be less than MAXVALUE. 
 if (!($MinValue -le $Start_With ))
  { Throw "Start_With($Start_With) ne peut pas être inférieur à MinValue($MinValue)."}
 elseif (!($MinValue -lt $MaxValue))
  { Throw "MinValue($MinValue) doit être inférieure à MaxValue($MaxValue)."}
 # MAXVALUE must be equal to or greater than START WITH and must be greater than MINVALUE.
 if (!($MaxValue -ge $Start_With))
   { Throw "Start_With($Start_With) ne peut pas être supérieur à MaxValue($MaxValue)."}
 elseif (!($MaxValue -gt $MinValue))
  { Throw "MaxValue($MaxValue) doit être supérieure à MinValue($MinValue)."}
  
  #On test s'il est possible d'itérer au moins une fois.
  #La construction suivant est valide mais pour un seul chiffre :
  # $Sq=Create-Sequence $N $C -inc 1 -min 0 -max 5 -start 5
  # $Sq=Create-Sequence $N $C -inc -1 -min 0 -max 2 -start 0
    
  #Start_with n'est pas pris en compte dans ce calcul, on autorise donc un séquence proposant un seul nombre.
  #Si dans ce cas on précise le switch -Cycle on a bien plusieurs itérations :
  # $Sq=Create-Sequence $N $C -inc 1 -min 0 -max 5 -start 5 -cycle

  #On cast $Increment_By car sa valeur peut être égale à [int]::MinValue, d'où une exception lors de l'appel à Abs
  # La documentation Oracle précise l'opérateur -lt mais dans ce cas la séquence suivante est impossible :
  #  Create-Sequence $N $C -min 1 -max 2 
 if (!([system.Math]::Abs([Long]$Increment_By) -le ($MaxValue-$MinValue)) )
  { Throw "Increment_By($Increment_By) doit être inférieur ou égale à MaxValue($MaxValue) moins MinValue($MinValue)."} 

#Création de la séquence
 $Sequence= new-object System.Management.Automation.PsObject
 # Ajout des propriétés en R/O, le code est créé dynamiquement
$MakeReadOnlyMember=@"
`$Sequence | add-member ScriptProperty Name         -value {"$Sequence_Name"}   -Passthru|`
             add-member ScriptProperty Comment      -value {"$Comment"}         -Passthru|`
             add-member ScriptProperty Increment_By -value {[int]$Increment_By} -Passthru|`
             add-member ScriptProperty MaxValue     -value {[int]$MaxValue}     -Passthru|`
             add-member ScriptProperty MinValue     -value {[int]$MinValue}     -Passthru|`
             add-member ScriptProperty Start_With   -value {[int]$Start_With}   -Passthru|`
             add-member ScriptProperty Cycle        -value {`$$Cycle}           -Passthru|`
             add-member ScriptProperty CurrVal      -value {[int]$Start_With}
"@
  Invoke-Expression $MakeReadOnlyMember
  
  #La méthode NextVal renvoie en fin de traitement la valeur courante du membre Currval
 $Sequence | add-member ScriptMethod NextVal {   
                          $NewValue=$this.CurrVal + $this.Increment_By
                          write-debug "this $this"
                          write-debug "NewValue $NewValue"
                           
                           #Déclaration paramétrée pour la redéfinition du membre CurrVal
                           #Le paramètre -Force annule et remplace la définition du membre spécifié
                          $RazMember="`$this | add-member -Force ScriptProperty CurrVal  -value {0}"
                                                                                                  
                          switch ([System.Math]::Sign($this.Increment_By))
                          {  
                              #MAXVALUE cannot be made to be less than the current value
                             1  { if ($NewValue -gt  $this.MaxValue)
                                  { write-debug "Borne maximum atteinte."
                                    
                                    if ($this.Cycle -eq $true) #Dans ce cas on recommence
                                     { #On construit (par formatage) la définition du membre CurrVal 
                                       #puis on reconstruit le membre.
                                      Invoke-Expression ($RazMember -F "{[int]$this.MinValue}")
                                     } 
                                    else {Throw "La séquence $($this.Name).Nextval a atteint la valeur maximum autorisée."}
                                  }
                                  else { Invoke-Expression ($RazMember -F "{[int]$NewValue}")}
                                }#Séquence ascendante

                              #MINVALUE cannot be made to exceed the current value 
                            -1  { if ($NewValue -lt  $this.MinValue)
                                  { write-debug "Borne minimum atteinte."
                                    if ($this.Cycle -eq $true)
                                     {Invoke-Expression ($RazMember -F "{[int]$this.MaxValue}") }
                                    else {Throw "La séquence $($this.Name).Nextval a atteint la valeur minimum autorisée."}
                                  }
                                  else {Invoke-Expression ($RazMember -F "{[int]$NewValue}") }
                                }#Séquence descendante
                             else {Throw "Erreur dans la méthode Nextval."}    
                          }#switch
                           #Renvoi la nouvelle valeur
                          $this.CurrVal
                          write-debug "this $this"
                        }

 write-Debug "[Valeurs de la séquence]"
 write-Debug "Sequence_Name $Sequence_Name"
 write-Debug "Comment $Comment"
 write-Debug "Increment_By $Increment_By" 
 write-Debug "MaxValue $MaxValue"
 write-Debug "MinValue $MinValue"
 write-Debug "Start_With $Start_With"  
 write-Debug "Cycle $Cycle"        
 write-Debug "Current $Current"
 write-Debug "----"
 write-Debug  $Sequence

  #Spécifie l'affichage des propriétés par défaut
  #On évite ainsi l'usage d'un fichier de type .ps1xml
  #From http://poshoholic.com/2008/07/05/essential-powershell-define-default-properties-for-custom-objects/
 $DefaultProperties =@(
  'Name',
  'CurrVal', 
  'Increment_By',
  'MaxValue',
  'MinValue',
  'Start_With',
  'Cycle',
  'Comment')
 $DefaultPropertySet=New System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$DefaultProperties)
 $PSStandardMembers=[System.Management.Automation.PSMemberInfo[]]@($DefaultPropertySet)
 $Sequence|Add-Member MemberSet PSStandardMembers $PSStandardMembers

 return $Sequence
}

# Examples :

#  # Valeur pas défaut
#   #Séquence ascendante
# $Sq=Create-Sequence "SEQ_Test"
# $Sq=Create-Sequence "SEQ_Test" ""
# $Sq=Create-Sequence "SEQ_Test" "Séquence de test"
# $Sq=Create-Sequence "SEQ_Test" "Séquence de test" -cycle
#  #Valeur pas défaut d'une séquence ascendante
# $Sq=Create-Sequence "SEQ_Test" "Séquence de test" -min 1 -max ([int32]::MaxValue) -inc 1 -start 1
#  #Valeur pas défaut d'une séquence descendante
# $Sq=Create-Sequence "SEQ_Test" "Séquence de test" -min ([int32]::MinValue) -max -1 -inc -1 -start -1
# 
#  #Incrément de 2
# $Sq=Create-Sequence "SEQ_Test" "Séquence de test" -inc 2
#  #Incrément négatif
# $Sq=Create-Sequence "SEQ_Test" "Séquence de test" -inc -1
# 
# 
# $N="SEQ_Test" 
# $C="Séquence de test"
#  
#  #Suite ascendante maximum, de [int32]::MinValue à [int32]::MaxValue débutant à [int32]::MinValue
# $Sq=Create-Sequence $N $C -min ([int32]::MinValue+1) -start ([int32]::MinValue+1)
#  #Suite descendante maximum, de [int32]::MinValue à [int32]::MaxValue débutant à [int32]::MaxValue
# $Sq=Create-Sequence $N $C -min ([int32]::MinValue+1) -max ([int32]::MaxValue) -start ([int32]::MaxValue) -inc -1
# 
#  #suite ascendante débutant à 0 et finissant à 255
# $Sq=Create-Sequence $N $C -min 0 -max 255
#  
#  
#  #Valeur minimum
#   #suite ascendante de 2 nombres 
# $Sq=Create-Sequence $N $C -minvalue 0 -maxvalue 1
#   #suite descendante de 2 nombres  
# $Sq=Create-Sequence $N $C -minvalue 0 -maxvalue 1  -inc -1
#   #suite de 2 nombres positifs avec un pas de 2 
# $sq=Create-Sequence $N $C -min 1 -max 3 -inc 2
#  
#  #"suite" de 1 nombre : 2 
# $sq=Create-Sequence $N $C -min 1 -max 2 -start 2
#  #"suite" de 1 nombre : 5
# $Sq=Create-Sequence $N $C -min 0 -max 5 -inc 1 -start 5
#  #"suite" de 1 nombre : 0
# $Sq=Create-Sequence $N $C -min 0 -max 2 -inc -1 -start 0
# 
#  #suite cyclique ascendante débutant à 2, ensuite chaque cycle débutera à 1, c'est à dire la valeur de MinValue
# $sq=Create-Sequence $N $C -min 1 -max 2 -start 2 -cycle
#  #suite cyclique ascendante  débutant à 5, ensuite chaque cycle débutera à 0
# $Sq=Create-Sequence $N $C -min 0 -max 5 -inc 1 -start 5 -cycle
#  #suite cyclique descendante débutant à 0, ensuite chaque cycle débutera aussi à 0
# $Sq=Create-Sequence $N $C -min 0 -max 2 -inc -1 -start 0 -cycle
# 
#   #MaxValue à 0, pour une suite descendante uniquement 
# $Sq=Create-Sequence $N $C -maxvalue 0 -inc -1
# 
#   #suite descendante débutant à -1 jusqu'à [int32]::MinValue
# $Sq=Create-Sequence $N $C -maxvalue -1 -inc -1
#  #suite ascendante négative débutant [int32]::MinValue jusqu'à -1 
# $Sq=Create-Sequence $N $C -min -2147483648 -max -1 -inc 1 -start -2147483648

