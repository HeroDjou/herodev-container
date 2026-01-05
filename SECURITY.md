# Política de Segurança

## Credenciais padrão

**AVISO**: Este projeto usa credenciais padrão para facilitar o desenvolvimento local. **NÃO é adequado para ambientes de produção.**

### Senhas padrão incluídas

| Serviço | Usuário | Senha | Arquivo/Localização |
|---------|---------|-------|---------------------|
| MariaDB (root) | root | root | `scripts/init-mariadb.sh` |
| code-server | - | dev | `volumes/vscode/config/config.yaml` |
| File Browser | admin | adminadmin123 | Containerfile |
| Mongo Express | admin | admin | Containerfile |
| Grafana | admin | admin | Instalação padrão |


### Arquivos sensíveis

- `.backup-config` - Contém último caminho de backup usado
- `volumes/` - Dados persistentes (bancos de dados, projetos)
- `*.log` - Arquivos de log

### O que NÃO fazer

**NÃO** use este container em produção  
**NÃO** exponha diretamente à internet  
**NÃO** compartilhe backups com credenciais padrão  
**NÃO** commite o arquivo `.backup-config`  
**NÃO** use as mesmas senhas em outros ambientes

### O que fazer

Use apenas em rede local/localhost  
Mantenha backups em local seguro  
Atualize regularmente as dependências  
Use VPN se precisar acesso remoto

## Reportar vulnerabilidades

Se você descobrir uma vulnerabilidade de segurança neste projeto, por favor:

1. Abra uma issue
2. Inclua:
   - Descrição da vulnerabilidade
   - Passos para reproduzir
   - Impacto potencial
   - Sugestões de correção (se houver)

## Ambiente de produção

Se você realmente precisa usar algo similar em produção:

1. **Use imagens oficiais** do Docker Hub para cada serviço
2. **Configure SSL/TLS** com certificados válidos
3. **Implemente autenticação robusta** (OAuth, SAML, etc.)
4. **Use secrets management** (Docker Secrets, HashiCorp Vault)
5. **Ative logs de auditoria**
6. **Configure backups automáticos** criptografados
7. **Implemente rate limiting** e proteção DDoS
8. **Use rede isolada** para os containers
9. **Mantenha tudo atualizado** (patches de segurança)
10. **Faça pentests** regulares

## Licença e isenção de responsabilidade

Este software é fornecido "como está", sem garantias de qualquer tipo. O uso em ambientes não controlados é de inteira responsabilidade do usuário. Os mantenedores não se responsabilizam por:

- Perda de dados
- Violações de segurança
- Uso inadequado
- Danos diretos ou indiretos

Use por sua própria conta e risco.
